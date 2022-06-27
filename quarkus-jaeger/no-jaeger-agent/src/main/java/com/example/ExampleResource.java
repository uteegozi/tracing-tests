package com.example;

import javax.enterprise.context.RequestScoped;
import javax.inject.Inject;
import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;

import org.eclipse.microprofile.opentracing.Traced;

@Traced
@RequestScoped
@Path("/hello")
public class ExampleResource {

    @Inject
    ExampleService srv;

    @GET
    @Produces(MediaType.TEXT_PLAIN)
    public String hello() {
        try {
            Thread.sleep(100);
        } catch (InterruptedException e) {;
        }
        String msg = this.srv.msg();
        try {
            Thread.sleep(20);
        } catch (InterruptedException e) {;
        }
        return msg;
    }
}