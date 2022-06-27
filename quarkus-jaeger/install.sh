#!/bin/bash

function installApp(){
  cd "./${projectFolder}"
  # create a project where the application will be installed
  oc new-project "${appProject}"
  helm install traced-app ./src/main/helm/jaeger-app -n "${appProject}" ${parameters}
  # to allow the deployment in the trace-proj namespace to access the application images installed under trace-img
  # if there is a problem to add this policy, create the application images inside the same namespace like the deployment and then no extra policy is needed
  oc policy add-role-to-user system:image-puller system:serviceaccount:"${appProject}":traced-app-jaeger-app --namespace=trace-img
  cd ..
}

function installJaegerInstance(){
  if [ "${option}" == "APP_NS" ]; then
    if [ "${backendJaegerInstance}" == "INST1" ]; then
      oc apply -f ./jaeger-res/jaeger-allinone-inst1.yaml -n "${appProject}"
    elif [ "${backendJaegerInstance}" == "INST2" ]; then
      oc apply -f ./jaeger-res/jaeger-allinone-inst2.yaml -n "${appProject}"
    fi
  elif [ "${option}" == "OTHER_NS" ]; then
    oc new-project "${backendProject}"
    if [ "${backendJaegerInstance}" == "INST1" ]; then
      oc apply -f ./jaeger-res/jaeger-allinone-inst1.yaml -n "${backendProject}"
    elif [ "${backendJaegerInstance}" == "INST2" ]; then
      oc apply -f ./jaeger-res/jaeger-allinone-inst2.yaml -n "${backendProject}"
    elif [ "${backendJaegerInstance}" == "INST3" ]; then
      oc apply -f ./jaeger-res/jaeger-agentdaemonset.yaml -n "${backendProject}"
      # without below daemonset not created - would expect it to be part of the jaeger CR creation
      oc apply -f ./jaeger-res/hostport-scc-daemonset.yaml -n "${backendProject}"
    fi
  fi
}

# COLL_SAME_NS or COLL_DIFF_NS or AGENT_DAEMONSET or NO_AGENT
example=$1
installOption=$2
if [ -z $installOption ]; then
  installOption=INSTALL
fi

echo "${installOption}" "${example}"

#  projectFolder="through-jaeger-agent"
#  appProject="trace-proj"oc login --token=sha256~Fv2Y3JiTvPbZ_XTHnD66h-fqVFdY9t8krNrkYqxokxI --server=https://api.tem-lab01.fsi.rhecoeng.com:6443
#  parameters="--set jaegerAgent.installOption=auto --set jaegerAgent.jaegerInstance=inst2"
#  option="APP_NS"  # APP_NS | OTHER_NS
#  backendProject="trace-coll"
#  backendJaegerInstance=INST1 | INST2
if [ "${installOption}" == "INSTALL" ]; then
  if [ "${example}" == "COLL_SAME_NS" ]; then
    # first project auto inject true
    projectFolder="through-jaeger-agent"
    appProject="trace-proj"
    parameters="--set jaegerAgent.installOption=auto"
    option="APP_NS"
    backendJaegerInstance="INST1"
    installApp
    installJaegerInstance

    # second project auto inject with backend name (must be different from the first projects or else operator will connect to first projects collector)
    projectFolder="through-jaeger-agent"
    appProject="trace-proj2"
    parameters="--set jaegerAgent.installOption=auto --set jaegerAgent.jaegerInstance=jaeger-backend-inst2"
    option="APP_NS"
    backendJaegerInstance="INST2"
    installApp
    installJaegerInstance

  elif [ "${example}" == "COLL_DIFF_NS" ]; then
    # first project auto inject true
    projectFolder="through-jaeger-agent"
    appProject="trace-proj"
    parameters="--set jaegerAgent.installOption=auto"
    option="OTHER_NS"
    backendProject="trace-coll"
    backendJaegerInstance="INST1"
    installApp
    installJaegerInstance

    # second project auto inject with same backend name like first project - no need to install Jaeger since first project already did
    projectFolder="through-jaeger-agent"
    appProject="trace-proj2"
    parameters="--set jaegerAgent.installOption=auto --set jaegerAgent.jaegerInstance=jaeger-backend-inst1"
    installApp

  elif [ "${example}" == "AGENT_DAEMONSET" ]; then
    # first project without agent
    projectFolder="through-jaeger-agent"
    appProject="trace-proj"
    parameters="--set jaegerAgent.installOption=daemon"
    # for daemon installation
    option="OTHER_NS"
    backendProject="trace-agent-ds"
    backendJaegerInstance="INST3"
    installApp
    installJaegerInstance

    # second project without agent
    projectFolder="through-jaeger-agent"
    appProject="trace-proj2"
    parameters="--set jaegerAgent.installOption=daemon"
    installApp

  elif [ "${example}" == "NO_AGENT" ]; then
    # one project
    projectFolder="no-jaeger-agent"
    appProject="trace-proj"
    parameters="--set env.jaegerEndpoint=http://jaeger-backend-inst1-collector.trace-coll.svc.cluster.local:14268/api/traces"
    # jaeger instance
    option="OTHER_NS"
    backendProject="trace-coll"
    backendJaegerInstance="INST1"
    installApp
    installJaegerInstance
  fi
else  # UNINSTALL
  if [ "${example}" == "COLL_SAME_NS" ]; then
    helm uninstall traced-app -n trace-proj
    oc delete project trace-proj
    helm uninstall traced-app -n trace-proj2
    oc delete project trace-proj2

  elif [ "${example}" == "COLL_DIFF_NS" ]; then
    helm uninstall traced-app -n trace-proj
    oc delete project trace-proj
    helm uninstall traced-app -n trace-proj2
    oc delete project trace-proj2
    oc delete project trace-coll

  elif [ "${example}" == "AGENT_DAEMONSET" ]; then
    helm uninstall traced-app -n trace-proj
    oc delete project trace-proj
    helm uninstall traced-app -n trace-proj2
    oc delete project trace-proj2
    oc delete project trace-agent-ds

  elif [ "${example}" == "NO_AGENT" ]; then
    helm uninstall traced-app -n trace-proj
    oc delete project trace-proj
    oc delete project trace-coll

  fi
fi



