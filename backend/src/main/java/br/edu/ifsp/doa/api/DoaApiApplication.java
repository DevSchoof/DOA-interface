package br.edu.ifsp.doa.api;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;
import org.springframework.scheduling.annotation.EnableAsync;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
@EnableAsync
@ConfigurationPropertiesScan
public class DoaApiApplication {
    public static void main(String[] args) {
        SpringApplication.run(DoaApiApplication.class, args);
    }
}
