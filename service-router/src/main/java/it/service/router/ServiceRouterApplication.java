package it.service.router;

import java.util.Optional;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.ApplicationPidFileWriter;
import org.springframework.boot.context.event.ApplicationEnvironmentPreparedEvent;
import org.springframework.context.ApplicationListener;
import org.springframework.core.env.ConfigurableEnvironment;

@SpringBootApplication
public class ServiceRouterApplication {
	private static final Logger logger = LoggerFactory.getLogger(ServiceRouterApplication.class);

	public static void main(String[] args) {
		SpringApplication app = new SpringApplication(ServiceRouterApplication.class);

		app.addListeners((ApplicationListener<ApplicationEnvironmentPreparedEvent>) event -> {
			try {
				resolvePidFilePath(event.getEnvironment()).ifPresent(path -> {
					try {
						event.getSpringApplication().addListeners(new ApplicationPidFileWriter(path));
						logger.info("PID file writer initialized at {}", path);
					} catch (Exception e) {
						logger.error("Failed to add PID file writer for path: {}", path, e);
					}
				});
			} catch (Exception e) {
				logger.error("Error resolving PID file path", e);
			}
		});

		app.run(args);
	}

	public static Optional<String> resolvePidFilePath(ConfigurableEnvironment env) {
		return Optional.ofNullable(env.getProperty("spring.pid.file")).filter(path -> !path.isBlank());
	}
}