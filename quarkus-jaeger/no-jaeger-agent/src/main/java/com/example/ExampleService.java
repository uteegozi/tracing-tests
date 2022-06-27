package com.example;

import org.eclipse.microprofile.opentracing.Traced;
import javax.enterprise.context.RequestScoped;

@Traced
@RequestScoped
public class ExampleService {
    public String msg(){
        try {
            Thread.sleep(50);
        } catch (InterruptedException e) {;
        }
        return "hi-"+System.currentTimeMillis();
    }
}
