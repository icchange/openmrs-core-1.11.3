/**
 * This Source Code Form is subject to the terms of the Mozilla Public License,
 * v. 2.0. If a copy of the MPL was not distributed with this file, You can
 * obtain one at http://mozilla.org/MPL/2.0/. OpenMRS is also distributed under
 * the terms of the Healthcare Disclaimer located at http://openmrs.org/license.
 *
 * Copyright (C) OpenMRS Inc. OpenMRS is a registered trademark and the OpenMRS
 * graphic logo is a trademark of OpenMRS Inc.
 */
package org.openmrs;

import org.junit.Before;
import org.junit.Test;
import org.openmrs.util.RoleConstants;

import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;

public class UserTest {
	
	private User user;
	
	@Before
	public void setUp() throws Exception {
		user = new User();
		user.addRole(new Role("Some Role", "This is a test role"));
	}
	
	@Test
	public void hasRole_shouldHaveRole() throws Exception {
		assertTrue(user.hasRole("Some Role"));
	}
	
	@Test
	public void hasRole_shouldNotHaveRole() throws Exception {
		assertFalse(user.hasRole("Not A Role"));
	}
	
	@Test
	public void hasRole_shouldHaveAnyRoleWhenSuperUser() throws Exception {
		user.addRole(new Role(RoleConstants.SUPERUSER));
		assertTrue(user.hasRole("Not A Role"));
	}
	
	@Test
	public void hasRole_shouldNotHaveAnyRoleWhenSuperWhenIgnoreSuperUserFlagIsTrue() throws Exception {
		user.addRole(new Role(RoleConstants.SUPERUSER));
		assertFalse(user.hasRole("Not A Role", true));
	}
	
	@Test
	public void isSuperUser_shouldBeSuperUser() throws Exception {
		user.addRole(new Role(RoleConstants.SUPERUSER));
		assertTrue(user.isSuperUser());
	}
	
	@Test
	public void isSuperUser_shouldNotBeSuperUser() throws Exception {
		assertFalse(user.isSuperUser());
	}
	
}
