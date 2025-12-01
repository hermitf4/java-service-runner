package it.almadoc.gateway;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.Optional;

import org.junit.jupiter.api.Test;
import org.springframework.mock.env.MockEnvironment;

import it.service.router.ServiceRouterApplication;

class ServiceRouterApplicationTest {

	@Test
	void resolvePidFilePath_returnsValueWhenPropertySet() {
		MockEnvironment env = new MockEnvironment();
		env.setProperty("spring.pid.file", "test.pid");
		Optional<String> result = ServiceRouterApplication.resolvePidFilePath(env);
		assertTrue(result.isPresent());
		assertEquals("test.pid", result.get());
	}

	@Test
	void resolvePidFilePath_returnsEmptyWhenPropertyNotSet() {
		MockEnvironment env = new MockEnvironment();
		Optional<String> result = ServiceRouterApplication.resolvePidFilePath(env);
		assertTrue(result.isEmpty());
	}

	@Test
	void resolvePidFilePath_returnsEmptyWhenPropertyBlank() {
		MockEnvironment env = new MockEnvironment();
		env.setProperty("spring.pid.file", "   ");
		Optional<String> result = ServiceRouterApplication.resolvePidFilePath(env);
		assertTrue(result.isEmpty());
	}
}