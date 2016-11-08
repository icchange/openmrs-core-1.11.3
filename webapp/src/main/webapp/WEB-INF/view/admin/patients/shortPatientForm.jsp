<%@ include file="/WEB-INF/template/include.jsp" %>

<openmrs:require privilege="Add Patients" otherwise="/login.htm" redirect="/admin/patients/shortPatientForm.form" />

<%@ include file="/WEB-INF/template/header.jsp" %>

<openmrs:htmlInclude file="/scripts/calendar/calendar.js" />
<script type="text/javascript">
	//variable to cache the id of the checkbox of the selected preferred patientIdentifier
	var prefIdentifierElementId = null;
	var numberOfClonedElements = 0;
    var currentSelectedIdentifier = "";
	var idTypeLocationRequired = {};
	var currentIdentifierCount = ${fn:length(patientModel.identifiers)};
	<c:forEach items="${identifierTypes}" var="idType">
		idTypeLocationRequired[${idType.patientIdentifierTypeId}] = ${idType.locationBehavior == null || idType.locationBehavior == "REQUIRED"};
	</c:forEach>
	
	function addIdentifier(initialIdentifierSize) {
		var index = initialIdentifierSize+numberOfClonedElements;
		var tbody = document.getElementById('identifiersTbody');
		var row = document.getElementById('newIdentifierRow');
		var newrow = row.cloneNode(true);
		
		newrow.style.display = "";		
		newrow.id = 'identifiers[' + index + ']';
		tbody.appendChild(newrow);
		var inputs = newrow.getElementsByTagName("input");
		var selects = newrow.getElementsByTagName("select");
		var divs = newrow.getElementsByTagName("div");
		for (var i in divs){
			var div = divs[i];
			if(div && divs[i].title  == "location"){
				div.id = 'identifiers' + index + '_location';
			}
		}
		for (var i in inputs){
			var input = inputs[i];
			if(input && inputs[i].type == "hidden"){
				input.name = 'identifiers[' + index + '].location';
			}			
		}
		for (var i in selects) {
			var select = selects[i];
			if (select && selects[i].name == "identifierType") {
				select.name = 'identifiers[' + index + '].identifierType';
				select.id = 'identifiers[' + index + '].identifierType';
				$j(select).change(function(){
					toggleLocationBoxAndIndentifierTypeWarning(this.options[this.selectedIndex].value,'identifiers'+ index +'_location',index);
				});
                		$j(select).focus(function(){
                    			storeSelectedIdentifierType(this.options[this.selectedIndex].text);
                		});
			}
			else if (select && selects[i].name == "location") {					
				select.name = 'identifiers[' + index + '].location';
				select.id = 'identifiers'+ index +'_location';
			}
		}
		
		$j(newrow).find('.locationNotApplicableClass').attr('id', 'identifiers'+ index +'_location_NA')
		$j(newrow).find('#identifierTypeWarning').attr('id', 'identifierTypeWarning'+ index);

		for (var x = 0; x < inputs.length; x++) {
			var input = inputs[x];
			if (input && input.name == 'identifier' && input.type == 'text') {
				input.name = 'identifiers[' + index + '].identifier';
			}
			else if (input && input.name == 'preferred' && input.type == 'radio') {
				input.name = 'identifiers[' + index + '].preferred';
				input.id = 'identifiers[' + index + '].preferred';
			}
			else if (input && input.name == 'newIdentifier.voided' && input.type == 'checkbox') {
				//set the attributes of the corresponding hidden checkbox for voiding/unvoiding new identifiers
				input.name = 'identifiers[' + index + '].voided';
				input.id = 'identifiers[' + index + '].isVoided';
			}else if (input && input.name == 'closeButton' && input.type == 'button') {
				//set the onclick event for this identifier's remove button,
				//so that we check the corresponding hidden checkbox to mark a removed identifier
				$j(input).click(function(){
					removeRow(this, 'identifiers[' + index + '].isVoided', index);
				});
			}
		}

		currentIdentifierCount++;
		if(currentIdentifierCount > 1){
			$j("#identifiersTbody > tr:visible > td:last-child > input.closeButton").show();
		}
		
		numberOfClonedElements++;
	}
	
	function updateAge() {
		var birthdateBox = document.getElementById('birthdate');
		var ageBox = document.getElementById('age');
		try {
			var birthdate = parseSimpleDate(birthdateBox.value, '<openmrs:datePattern />');
			var age = getAge(birthdate);
			if (age > 0)
				ageBox.innerHTML = "(" + age + ' <openmrs:message code="Person.age.years"/>)';
			else if (age == 1)
				ageBox.innerHTML = '(1 <openmrs:message code="Person.age.year"/>)';
			else if (age == 0)
				ageBox.innerHTML = '( < 1 <openmrs:message code="Person.age.year"/>)';
			else
				ageBox.innerHTML = '( ? )';
			ageBox.style.display = "";
		} catch (err) {
			ageBox.innerHTML = "";
			ageBox.style.display = "none";
		}
	}
	
	function updateEstimated() {
		var input = document.getElementById("birthdateEstimatedInput");
		if (input) {
			input.checked = false;
			input.parentNode.className = "";
		}
		else
			input.parentNode.className = "listItemChecked";
	}
	
	// age function borrowed from http://anotherdan.com/2006/02/simple-javascript-age-function/
	function getAge(d, now) {
		var age = -1;
		if (typeof(now) == 'undefined') now = new Date();
		while (now >= d) {
			age++;
			d.setFullYear(d.getFullYear() + 1);
		}
		return age;
	}
	
	function removeRow(btn, checkBoxId, index) {
		refreshDuplicateIdentifierTypeWarningsAtRemove(index);
		var parent = btn.parentNode;
		while (parent.tagName.toLowerCase() != "tr")
			parent = parent.parentNode;
		
		parent.style.display = "none";		
		if(checkBoxId && document.getElementById(checkBoxId)){
			document.getElementById(checkBoxId).checked = true;
			document.getElementById(checkBoxId).value = true;
		}
		
		currentIdentifierCount --;
		var identifiersId = 'identifiers['+index+']';
		$j(document.getElementById(identifiersId)).remove();
	}
	
	function removeHiddenRows() {
		
		var rows = document.getElementsByTagName("TR");
		var i = 0;
		while (i < rows.length) {
			//donot remove the hidden row used as a prototype for new ones
			if (rows[i].id.startsWith('newIdentifierRow')) {
				rows[i].parentNode.removeChild(rows[i]);
			}
			else {
				i = i + 1;
			}
		}
	}

	/**
	 * Unchecks the current preferred patientIdentifier and checks the newly selected one
	 * whenever a user clicks the radio buttons for the patientidentifiers.
	 * @param radioElement the id of the radioButton for the selected identifier checkbox
	 */
	function updatePreferred(radioElement){
		if(prefIdentifierElementId && document.getElementById(prefIdentifierElementId))
			document.getElementById(prefIdentifierElementId).checked = false;
		
		radioElement.checked = true;		
		setPrefIdentifierElementId(radioElement.id);
	}

    /**
	 * Caches the id of the checkbox of the selected preferred patientIdentifier
	 *	 
	 * @param elementId the id of the radioButton for the selected identifier checkbox
	 */	
	function setPrefIdentifierElementId(elementId){
		prefIdentifierElementId = elementId;			
	}

	/**
	 * Utility function that checks if a given string starts with a specified string	 
	 *
	 * @param radioElement the radioButton for the selected identifier checkbox
	 */
	String.prototype.startsWith = function(prefix) {
	    return this.indexOf(prefix) === 0;
	}

	function voidedBoxClicked(chk) {
		//do nothing
	}

	function preferredBoxClick(obj) {
		//do nothing
	}

    function showOrHideDuplicateIdentifierTypeWarnings(index) {
        var equalCount=0;
        var identifierTypeWarningDivId="identifierTypeWarning"+index;
        var identifierTypeId;
        if(index==0) {
            identifierTypeId = 'identifiers' + index + '.identifierType';
        } else {
            identifierTypeId = 'identifiers[' + index + '].identifierType';
        }
        var jQueryObj = $j(document.getElementById(identifierTypeId));
        var identifierTypeName = jQueryObj.children("option").filter(":selected").text().trim();
        $j('.patientIdentifierTypeColumn select > option:selected').each(function () {
            if($j(this).text().trim()==identifierTypeName && identifierTypeName!='') {
                equalCount++;
            }
        });
        if(equalCount>1) {
            $j('#'+identifierTypeWarningDivId).show();
        } else {
            $j('#'+identifierTypeWarningDivId).hide();
        }
    }

    function refreshDuplicateIdentifierTypeWarningsAtChange(index) {
        var rootNode;
        var identifierTypeId;
        if(index==0) {
            identifierTypeId = 'identifiers' + index + '.identifierType';
        } else {
            identifierTypeId = 'identifiers[' + index + '].identifierType';
        }
        var jQueryObj = $j(document.getElementById(identifierTypeId));
        var identifierTypeName = jQueryObj.children("option").filter(":selected").text().trim();
        var duplicateCountForCurrentType = 0;
        var duplicateCountForPreviousType = 0;
        $j('.patientIdentifierTypeColumn select > option:selected').each(function () {
            if ($j(this).text().trim() == identifierTypeName && identifierTypeName!='') {
                if (this.parentNode.id.trim() != identifierTypeId) {
                    rootNode = $j(this.parentNode.parentNode.parentNode);
                    $j(rootNode).find('.duplicateIdentifierTypeWarning').find("div").show();
                    duplicateCountForCurrentType++;
                    if (duplicateCountForCurrentType < 2) {
                        $j(rootNode).find('.duplicateIdentifierTypeWarning').find("div").hide();
                    }
                }
            } else if ($j(this).text().trim() == currentSelectedIdentifier.trim()) {
                rootNode = $j(this.parentNode.parentNode.parentNode);
                $j(rootNode).find('.duplicateIdentifierTypeWarning').find("div").show();
                duplicateCountForPreviousType++;
                if (duplicateCountForPreviousType < 2 || currentSelectedIdentifier=='') {
                    $j(rootNode).find('.duplicateIdentifierTypeWarning').find("div").hide();
                }
            }
        });
        currentSelectedIdentifier = "";
    }

    function refreshDuplicateIdentifierTypeWarningsAtRemove(index) {
        var rootNode;
        var identifierTypeId;
        if(index==0) {
            identifierTypeId = 'identifiers' + index + '.identifierType';
        } else {
            identifierTypeId = 'identifiers[' + index + '].identifierType';
        }
        var jQueryObj = $j(document.getElementById(identifierTypeId));
        var identifierTypeName = jQueryObj.children("option").filter(":selected").text().trim();
        var duplicateCountForCurrentType = 0;
        $j('.patientIdentifierTypeColumn select > option:selected').each(function () {
            if ($j(this).text().trim() == identifierTypeName && identifierTypeName!='') {
                if (this.parentNode.id.trim() != identifierTypeId) {
                rootNode = $j(this.parentNode.parentNode.parentNode);
                $j(rootNode).find('.duplicateIdentifierTypeWarning').find("div").show();
                    duplicateCountForCurrentType++;
                    if (duplicateCountForCurrentType < 2) {
                        $j(rootNode).find('.duplicateIdentifierTypeWarning').find("div").hide();
                    }
                }
            }
        });
    }

    function storeSelectedIdentifierType(selectedIdentifierType) {
        currentSelectedIdentifier = selectedIdentifierType;
    }

    function toggleLocationBoxAndIndentifierTypeWarning(identifierType, location, index) {
        showOrHideDuplicateIdentifierTypeWarnings(index);
        refreshDuplicateIdentifierTypeWarningsAtChange(index, identifierType);
        toggleLocationBox(identifierType,location);
    }

    function toggleLocationBox(identifierType,location) {
		console.log(location);
		if (identifierType == '') {
			$j('#'+location + '_NA').hide();
			$j('#'+location).hide();
		}
		else if (idTypeLocationRequired[identifierType]) {
			$j('#'+location + '_NA').hide();
			$j('#'+location).show();
		} 
		else {
			$j('#'+location).hide();
			$j('#'+location + '_NA').show();
		}
	}
</script>

<style>
	th { text-align: left } 
	th.headerCell {
		border-top: 1px lightgray solid; 
		xborder-right: 1px lightgray solid
	}
	td.inputCell {
		border-top: 1px lightgray solid;
		}
		td.inputCell th {
			font-weight: normal;
		}
	.lastCell {
		border-bottom: 1px lightgray solid;
	}
</style>

<openmrs:globalProperty key="use_patient_attribute.mothersName" defaultValue="false" var="showMothersName"/>

<spring:hasBindErrors name="patientModel">
    <openmrs_tag:errorNotify errors="${errors}" />
</spring:hasBindErrors>

<form:form method="post" action="shortPatientForm.form" onsubmit="removeHiddenRows()" modelAttribute="patientModel">
	<c:if test="${patientModel.patient.patientId == null}"><h2><openmrs:message code="Patient.create"/></h2></c:if>
	<c:if test="${patientModel.patient.patientId != null}"><h2><openmrs:message code="Patient.edit"/></h2></c:if>

	<c:if test="${patientModel.patient.patientId != null}">
		<a href="${pageContext.request.contextPath}/patientDashboard.form?patientId=<c:out value="${patientModel.patient.patientId}" />">
			<openmrs:message code="patientDashboard.viewDashboard"/>
		</a>
		<br/>
	</c:if>
	
	<br/>
	
	<table id="parentTable" cellspacing="0" cellpadding="7">
	<tr class="parentTableRow">
		<th class="headerCell" valign="top"><openmrs:message code="Person.name"/></th>
		<td class="inputCell">
			<table id="personNameTable" class="childTable" cellspacing="2">				
				<thead>
					<openmrs:portlet url="nameLayout" id="namePortlet" size="columnHeaders" parameters="layoutShowTable=false|layoutShowExtended=false" />
				</thead>
				<spring:nestedPath path="personName">
				<openmrs:portlet url="nameLayout" id="namePortlet" size="inOneRow" parameters="layoutMode=edit|layoutShowTable=false|layoutShowExtended=false" />
				</spring:nestedPath>
			</table>
		</td>
	</tr>
	<tr class="parentTableRow">
		<th class="headerCell" valign="top"><openmrs:message code="PatientIdentifier.title.endUser"/></th>
		<td class="inputCell">
			<table id="identifiers" class="childTable" cellspacing="2">
				<tr class="childTableRow">
					<td class="idNumberHeaderColumn"><openmrs:message code="PatientIdentifier.identifier"/><span class="required">*</span></td>
					<openmrs:extensionPoint pointId="newPatientForm.identifierHeader" />
					<td class="idNumberHeaderColumn"><openmrs:message code="PatientIdentifier.identifierType"/></td>
					<td class="idNumberHeaderColumn">
						<c:if test="${identifierLocationUsed}">
							<openmrs:message code="PatientIdentifier.location.identifier"/>
						</c:if>
					</td>
					<td class="idNumberHeaderColumn"><openmrs:message code="general.preferred"/></td>
					<td class="idNumberHeaderColumn"></td>
				</tr>
				<tbody id="identifiersTbody">
					<c:forEach var="id" items="${patientModel.identifiers}" varStatus="varStatus">
					<%-- Don't display new identifiers that have been removed from the UI in previous submits that had errors--%>
					<spring:nestedPath path="identifiers[${varStatus.index}]">
					<tr id="existingIdentifiersRow[${varStatus.index}]" <c:if test="${id.voided}">style='display: none'</c:if>>					
					<td class="idNumberDataColumn" valign="top">
						<openmrs:userProperty key="defaultLocation" defaultValue="" var="userlocation"/>
						<openmrs:hasPrivilege privilege="Change location">
							<spring:bind path="identifier">
								<input type="text" size="30" name="${status.expression}" value="${status.value}" />					
							</spring:bind>
						</openmrs:hasPrivilege>
						<openmrs:hasPrivilege privilege="Change location" inverse="true">
						<c:choose>	
							<c:when test="${empty id.location || id.location.id == userlocation || id.identifierType.locationBehavior == 'NOT_USED'}">					
								<spring:bind path="identifier">
								<input type="text" size="30" name="${status.expression}" value="${status.value}" />					
								</spring:bind>
							</c:when>
							<c:otherwise>
								<spring:bind path="identifier">
									${status.value}
									<input name="${status.expression}" type="hidden" value="${status.value}"/>
								</spring:bind>
							</c:otherwise>
						</c:choose>
						</openmrs:hasPrivilege>
					</td>
					<openmrs:extensionPoint pointId="newPatientForm.identifierBody" />
					<td class="idNumberDataColumn patientIdentifierTypeColumn" valign="top">
						<openmrs:hasPrivilege privilege="Change location">
						<form:select path="identifierType" onfocus="storeSelectedIdentifierType(this.options[this.selectedIndex].text)" onchange="toggleLocationBoxAndIndentifierTypeWarning(this.options[this.selectedIndex].value,'initialLocationBox${varStatus.index}', '${varStatus.index}');" >
							<form:option value=""></form:option>
							<form:options items="${identifierTypes}" itemValue="patientIdentifierTypeId" itemLabel="name" />
					        </form:select>
						</openmrs:hasPrivilege>
						<openmrs:hasPrivilege privilege="Change location" inverse="true">
						<c:choose>	
							<c:when test="${empty id.location || id.location.id == userlocation || id.identifierType.locationBehavior == 'NOT_USED' }">
								<form:select path="identifierType" onfocus="storeSelectedIdentifierType(this.options[this.selectedIndex].text)" onchange="toggleLocationBoxAndIndentifierTypeWarning(this.options[this.selectedIndex].value,'initialLocationBox${varStatus.index}', '${varStatus.index}');" >
									<form:option value=""></form:option>
									<form:options items="${identifierTypes}" itemValue="patientIdentifierTypeId" itemLabel="name" />
					        		</form:select>
							</c:when>
							<c:otherwise>
								${id.identifierType}
								<input name="identifiers${varStatus.index}.identifierType" type="hidden" value="${id.identifierType}"/>
							</c:otherwise>
						</c:choose>
						</openmrs:hasPrivilege>
					</td>
					<td class="idNumberDataColumn" valign="top">
						<c:set var="behavior" value="${id.identifierType.locationBehavior}"/>
						<div id="initialLocationBox${varStatus.index}" style="${(behavior == 'NOT_USED' || empty id.identifierType) ? 'display:none;' : ''}">
							<openmrs:hasPrivilege privilege="Change location">
								<form:select path="location">
									<form:option value=""></form:option>
									<form:options items="${locations}" itemValue="locationId" itemLabel="name" />
								</form:select>
							</openmrs:hasPrivilege>
							<openmrs:hasPrivilege privilege="Change location" inverse="true">
								<div style="border-style: groove;border-width: 1px;" >
								<c:forEach items="${locations}" var="location" >
									<c:choose>
										<c:when test="${empty id.location || id.identifierType.locationBehavior == 'NOT_USED'}">
											<c:if test="${location.id == userlocation}">
												${location.name}
												<input id="identifiers${varStatus.index}_location" name="identifiers[${varStatus.index}].location" type="hidden" value="${userlocation}"/>
											</c:if>
										</c:when>
										<c:otherwise>
											<c:if test="${location.id == id.location.id}">
												${location.name}
												<input id="identifiers${varStatus.index}_location" name="identifiers[${varStatus.index}].location" type="hidden" value="${id.location.id}"/>
											</c:if>
										</c:otherwise>
									</c:choose>

								</c:forEach>
								</div>
							</openmrs:hasPrivilege>
						</div>
						<div id="initialLocationBox${varStatus.index}_NA" style="${behavior == 'NOT_USED' ? '' : 'display:none;'}">
							<c:if test="${identifierLocationUsed}">
								<openmrs:message code="PatientIdentifier.location.notApplicable"/>
							</c:if>
						</div>
					</td>
					<td class="idNumberDataColumn" valign="middle" align="center">
						<spring:bind path="preferred">
						<input type="hidden" name ="_${status.expression}" value="${status.value}"/>
						<input id="${status.expression}" type="radio" name="${status.expression}" value="true" onclick="updatePreferred(this)" <c:if test="${status.value}">checked=checked</c:if> />
						<c:if test="${status.value}">
							<script type="text/javascript">
								setPrefIdentifierElementId("${status.expression}");
							</script>
						</c:if>
						</spring:bind>						
					</td>
					<td class="idNumberDataColumn" valign="middle">
						<spring:bind path="voided">
						<input type="hidden" name="_${status.expression}" value=""/>		
						<input id="identifiers[${varStatus.index}].isVoided" type="checkbox" name="${status.expression}" value="${status.value}" <c:if test="${id.voided}">checked='checked'</c:if> style="display:none"/>						
						<input type="button" name="closeButton" onClick="removeRow(this, 'identifiers[${varStatus.index}].isVoided','${varStatus.index}');" class="closeButton" value='<openmrs:message code="general.remove"/>' <c:if test="${(varStatus.first && varStatus.last)}">style="display: none;"</c:if> />
						</spring:bind>
					</td>
					<td class="duplicateIdentifierTypeWarning">
						<div style="display: none; background-color: #ffff88" id="identifierTypeWarning0">
								<openmrs:message code="Patient.warning.duplicateIdentifierTypes"/>
						</div>
					</td>
					</tr>
					</spring:nestedPath>
					</c:forEach>
					
					<%-- The row from which to clone new identifiers --%>
					<tr id="newIdentifierRow" style="display: none">
					<td class="idNumberDataColumn" valign="top">
						<input type="text" size="30" name="identifier" value="" />
					</td>
					<openmrs:extensionPoint pointId="newPatientForm.identifierBody" />
					<td class="idNumberDataColumn patientIdentifierTypeColumn" valign="top">
						<select name="identifierType">
							<option value=""></option>
							<openmrs:forEachRecord name="patientIdentifierType">
							<option value="${record.patientIdentifierTypeId}">
                                <c:out value="${record.name}" />
							</option>
							</openmrs:forEachRecord>
						</select>						
					</td>
					<td class="idNumberDataColumn" valign="top">
						<openmrs:hasPrivilege privilege="Change location">
						<select name="location" style="display: none;">
							<option value=""></option>
							<openmrs:forEachRecord name="location">
								<option value="${record.locationId}"<c:if test="${identifierLocationUsed && record == defaultLocation}"> selected="selected"</c:if>>
                                    <c:out value="${record.name}" />
								</option>
							</openmrs:forEachRecord>
						</select>
						</openmrs:hasPrivilege>
						<openmrs:hasPrivilege privilege="Change location" inverse="true">
							<div title="location" style="display: none;border-style: groove;border-width: 1px;" >
							<openmrs:userProperty key="defaultLocation" defaultValue="" var="userlocation"/>
							<c:forEach items="${locations}" var="location" >
								<c:if test="${location.id == userlocation}">
									${location.name}
									<input type="hidden" value="${userlocation}"/>
								</c:if>
							</c:forEach>
							</div>
						</openmrs:hasPrivilege>
						<span class="locationNotApplicableClass" style="display:none;">
							<c:if test="${identifierLocationUsed}">
								<openmrs:message code="PatientIdentifier.location.notApplicable"/>
							</c:if>
						</span>
					</td>
					<td class="idNumberDataColumn" valign="middle" align="center">
						<input type="radio" name="preferred" value="true" onclick="updatePreferred(this)" />
					</td>					
					<td class="idNumberDataColumn" valign="middle" align="center">
						<input type="checkbox" name="newIdentifier.voided" value="false" style="display: none"/>
						<input type="button" name="closeButton" class="closeButton" value='<openmrs:message code="general.remove"/>'/>
					</td>
                        <td class="duplicateIdentifierTypeWarning">
                            <div style="display: none; background-color: #ffff88" id="identifierTypeWarning">
                                <openmrs:message code="Patient.warning.duplicateIdentifierTypes"/>
                            </div>
                        </td>
					</tr>
				</tbody>
			</table>			
			<input type="button" class="smallButton" onclick="addIdentifier(${fn:length(patientModel.identifiers)})" value="<openmrs:message code="PatientIdentifier.add" />" hidefocus />
		</td>
	</tr>
	<tr class="parentTableRow">
		<th class="headerCell" valign="top"><openmrs:message code="patientDashboard.demographics"/></th>
		<td class="inputCell">
			<table id="demographicsTable" class="childTable">
				<tr class="childTableRow">
					<td class="demographicsHeaderColumn"><openmrs:message code="Person.gender"/></td>
					<td class="demographicsHeaderColumn"><openmrs:message code="Person.age"/></td>
					<td class="demographicsHeaderColumn"><openmrs:message code="Person.birthdate"/> <i style="font-weight: normal; font-size: 0.8em;">(<openmrs:message code="general.format"/>: <openmrs:datePattern />)</i></td>
				</tr>
				<tr class="childTableRow">
					<td class="demographicsDataColumn" style="padding-right: 3em">
						<spring:bind path="patient.gender">
								<openmrs:forEachRecord name="gender">
									<input type="radio" name="${status.expression}" id="${record.key}" value="${record.key}" <c:if test="${record.key == status.value}">checked</c:if> />
										<label for="${record.key}"> <openmrs:message code="Person.gender.${record.value}"/> </label>
								</openmrs:forEachRecord>
							<c:if test="${status.errorMessage != ''}"><span class="error">${status.errorMessage}</span></c:if>
						</spring:bind>
					</td>
					<td class="demographicsDataColumn" style="padding-right: 3em">
						<span id="age"></span>
					</td>
					<td class="demographicsDataColumn" style="padding-right: 3em">
						<script type="text/javascript">
							function updateEstimated(txtbox) {
								var input = document.getElementById("birthdateEstimatedInput");
								if (input) {
									input.checked = false;
									input.parentNode.className = "";
								}
								else if (txtbox)
									txtbox.parentNode.className = "listItemChecked";
							}
						</script>
						<spring:bind path="patient.birthdate">			
							<input type="text" 
									name="${status.expression}" size="10" id="birthdate"
									value="${status.value}"
									onChange="updateAge(); updateEstimated(this);"
									onfocus="showCalendar(this,60)" />
							<c:if test="${status.errorMessage != ''}"><span class="error">${status.errorMessage}</span></c:if> 
						</spring:bind>
						
						<span id="birthdateEstimatedCheckbox" class="listItemChecked" style="padding: 5px;">
							<spring:bind path="patient.birthdateEstimated">
								<label for="birthdateEstimatedInput"><openmrs:message code="Person.birthdateEstimated"/></label>
								<input type="hidden" name="_${status.expression}">
								<input type="checkbox" name="${status.expression}" value="true" 
									   <c:if test="${status.value == true}">checked</c:if> 
									   id="birthdateEstimatedInput" 
									   onclick="if (!this.checked) updateEstimated()" />
								<c:if test="${status.errorMessage != ''}"><span class="error">${status.errorMessage}</span></c:if>
							</spring:bind>
						</span>
						
						<script type="text/javascript">
							if (document.getElementById("birthdateEstimatedInput").checked == false)
								updateEstimated();
							updateAge();
						</script>
					</td>
				</tr>
			</table>
		</td>
	</tr>

	<tr class="parentTableRow">
		<th class="headerCell" valign="top"><openmrs:message code="Person.address"/></th>
		<td class="inputCell">

		    								<style>
            								  .map {
            									height: 600px;
            									width: 1000px;
            								  }
            								</style>
                                            <label id="projection" style="display:none">EPSG:3857</label>
                                            <!-- <label id="mouse-position"></label>
                                            <label id="precision"  style="display:none">12</label> -->
                                            <h3>Please indicate where the patient lives by clicking on the map below with the mouse</h3>
                                            <div id="map" class="map"></div>
            								<div id="popup"></div>
            							<openmrs:htmlInclude file="/scripts/ol.js" />
            							<openmrs:htmlInclude file="/scripts/ol.css" />
                                        <!--
            							<link rel="stylesheet" href="./Marker Example/ol.css" type="text/css">
            							<script src="./Marker Example/ol.js" type="text/javascript"></script>
            							<script src="./Marker Example/jquery.min.js" type="text/javascript"></script>
            							<script src="./Marker Example/bootstrap.js" type="text/javascript"></script>
            							<link rel="stylesheet" href="./Marker Example/bootstrap.css" type="text/css">-->

            <br/>
			<spring:nestedPath path="personAddress">
			    <!-- The following line of code is completely responsible for rendering of the patient address
			    according to the template provided in the settings -->
				<openmrs:portlet url="addressLayout" id="addressPortlet" size="full" 
					parameters="layoutShowTable=true|layoutShowExtended=false|isNew=${patientModel.personAddress.personAddressId == null}" />


				<script type="text/javascript">
                                                                ////////////////////////////////////////////////////////////////////////////////////
                                                                /*
                            									var projection = new ol.proj.Projection({
                                                                  code: 'EPSG:3048',
                                                                  // The extent is used to determine zoom level 0. Recommended values for a
                                                                  // projection's validity extent can be found at http://epsg.io/.
                                                                  extent: [224544.8015, 3821684.0528, 775455.1985, 8325798.2469],
                                                                  units: 'm'
                                                                });
                                                                ol.proj.addProjection(projection);
                            									*/

                            									var testAddress = document.getElementById('personAddress.address2').value;
                            									console.log("Acquired address2: " + testAddress);


                                                                var mousePositionControl = new ol.control.MousePosition({
                                                                  coordinateFormat: ol.coordinate.createStringXY(4),
                                                                  projection: 'EPSG:4326',
                                                                  // comment the following two lines to have the mouse position
                                                                  // be placed within the map.
                                                                  //className: 'custom-mouse-position',
                                                                  //target: document.getElementById('mouse-position'),
                                                                  undefinedHTML: '&nbsp;'
                                                                });
                                                                //var extent = [36.77275709999483, -1.3179486, 36.8050213, -1.3059372];

                                                                format = 'image/png';
                            /*
                                                                function CenterMap(lon, lat) {
                                                                    console.log("Long: " + lon + " Lat: " + lat);
                                                                    var coordinate = [lon, lat];
                                                                    console.log("Together: " + coordinate);
                                                                    map.getView().setCenter(ol.proj.transform([0,0], 'EPSG:4326', 'EPSG:3857'));
                                                                    map.getView().setZoom(5);
                                                                }
                            */


                                                                var map = new ol.Map({
                                                                  controls: ol.control.defaults({
                                                                    attributionOptions: /** @type {olx.control.AttributionOptions} */ ({
                                                                      collapsible: false
                                                                    })
                                                                  }).extend([mousePositionControl]),
                                                                  layers: [
                                                                    new ol.layer.Tile({
                                                                      source: new ol.source.OSM()
                                                                    })
                                                                  ],
                                                                  //renderer: exampleNS.getRendererFromQueryString(),
                                                                  target: 'map',
                                                                  view: new ol.View({
                                                                    //center: ol.proj.transform([36.79564, -1.31120], 'EPSG:4326', 'EPSG:3857'),
                                                                    center: [4095101.1653739787, -146044.79830809683],
                            										//projection: "EPSG:3857",
                            										//center: [36.79564, -1.31120],
                                                                    zoom: 16,
                            										maxZoom: 18,
                            										minZoom: 16
                                                                  }),
                                                                  //units:'m',

                                                                  //displayProjection: "EPSG:4326"
                                                                });
                            									//CenterMap(4095385.640191469, -146138.71556416765);
                                                                //CenterMap(36.795640, -1.311200);

                            									/*
                                                                var tiled = new ol.layer.Image({
                            										extent: [36.77275709999483, -1.3179486, 36.8050213, -1.3059372],
                            										source: new ol.source.ImageWMS(
                            										{
                            										  url: 'http://68.148.5.121:8080/geoserver/wms',
                            										  params: {
                            													'LAYERS': 'All Kibera Clinics',
                            													'STYLES': '',
                            													'FORMAT': 'image/png',
                            													'TILED': 'true'
                            													//'srs': 'EPSG:3048',
                            													//'bbox': '36.77275709999483,-1.3179486,36.8050213,-1.3059372'
                            												  },
                            										  serverType: 'geoserver'
                            										})
                                                                });
                            									map.addLayer(tiled);
                            									*/

                            									var element = document.getElementById('popup');

                            									var popup = new ol.Overlay({
                            									  element: element,
                            									  positioning: 'bottom-center',
                            									  stopEvent: false
                            									});
                            									map.addOverlay(popup);

                                                                var projectionSelect = new ol.dom.Input(document.getElementById('projection'));
                                                                projectionSelect.bindTo('value', mousePositionControl, 'projection')
                                                                  .transform(
                                                                    function(code) {
                                                                      // projectionSelect.value -> mousePositionControl.projection
                                                                      return ol.proj.get(/** @type {string} */ (code));
                                                                    },
                                                                    function(projection) {
                                                                      // mousePositionControl.projection -> projectionSelect.value
                                                                      return projection.getCode();
                                                                    });

                                                                var precisionInput = 12;/*document.getElementById('precision');
                                                                precisionInput.addEventListener('change', function() {
                                                                  var format = ol.coordinate.createStringXY(precisionInput.valueAsNumber);
                                                                  mousePositionControl.setCoordinateFormat(format);
                                                                }, false);*/

                            									var c = [0,0];
                            									document.getElementById('personAddress.latitude').readOnly = true;
                            									document.getElementById('personAddress.longitude').readOnly = true;
                            									//Here we should also check whether the address ids are in addresses[1].latitude format as opposed to personAddress.latitude format
                            									if (document.getElementById('personAddress.latitude') != null && document.getElementById('personAddress.longitude') != null)
                            									{
                            										c = [document.getElementById('personAddress.latitude').value, document.getElementById('personAddress.longitude').value];
                            									}
                                                                var iconFeature = new ol.Feature({
                                                                  geometry: new ol.geom.Point(c),
                            									  amenity: 'Dwelling',
                                                                  name: 'You live here'
                                                                });

                            									//Setting marker style
                                                                var iconStyle = new ol.style.Style({
                                                                  image: new ol.style.Icon(/** @type {olx.style.IconOptions} */ ({
                                                                    anchor: [0.48, 25],
                                                                    anchorXUnits: 'fraction',
                                                                    anchorYUnits: 'pixels',
                                                                    opacity: 0.75,
                                                                    scale: 2.00,
                                                                    src: '../../images/marker.png'
                                                                  }))
                                                                });
                            									//Assigning marker style
                                                                iconFeature.setStyle(iconStyle);

                            									//Setting and assigning clinic marker styles
                            									var image = new ol.style.Circle({
                            									  radius: 8,
                            									  fill: null,
                            									  stroke: new ol.style.Stroke({color: 'red', width: 0})
                            									});
                            									var styles = {/*
                            									  'Point': [new ol.style.Style({
                            										image: image
                            									  })],*/
                            									  'Point': [new ol.style.Style({
                            										image: new ol.style.Icon(/** @type {olx.style.IconOptions} */ ({
                                                                    anchor: [0.4, 2],
                                                                    anchorXUnits: 'fraction',
                                                                    anchorYUnits: 'pixels',
                                                                    opacity: 0.75,
                                                                    src: '../../images/hospital.p.16.png'
                                                                  }))
                            									  })]
                            									}

                            									var alliedStyles = {};

                            									var alliedStyleFunction = function(feature, resolution) {
                                                                    var text = resolution < 18 ? feature.get('name') : '';
                                                                    //return styles[feature.getGeometry().getType()];

                                                                    if (!alliedStyles[text]) {
                                                                    			alliedStyles[text] =
                                                                    			    [new ol.style.Style
                                                                    			    ({
                                                                                        image: new ol.style.Icon(/** @type {olx.style.IconOptions} */
                                                                                        ({
                                                                                            anchor: [0.5, 10],
                                                                                            anchorXUnits: 'fraction',
                                                                                            anchorYUnits: 'pixels',
                                                                                            opacity: 1.00,
                                                                                            scale: 2.00,
                                                                                            src: '../../images/openmrs_logo_tiny.png'
                                                                                        })),
                                                                                        text : new ol.style.Text({
                                                                                            font : '20px Calibri,sans-serif,bold',
                                                                                            text : text,
                                                                                            fill : new ol.style.Fill({
                                                                                                color : '#000'
                                                                                            }),
                                                                                            offsetY : -23, //30
                                                                                            stroke : new ol.style.Stroke({
                                                                                                color : '#fff',
                                                                                                width : 4
                                                                                            })
                                                                                        })
                                                                                    })];
                                                                    		}
                                                                    		return alliedStyles[text];
                            									};





                                                                var alliedVectorSource = new ol.source.GeoJSON(
                                                                                            /** @type {olx.source.GeoJSONOptions} */ ({
                                                                                            format: new ol.format.GeoJSON({
                                                                                                defaultProjection: 'EPSG:4326'
                                                                                            }),
                                                                                            projection: 'EPSG:3857',
                                                                                            object:
                                                                                            {
                                                                  "type": "FeatureCollection",
                                                                  "generator": "overpass-turbo",
                                                                  "copyright": "The data included in this document is from www.openstreetmap.org. The data is made available under ODbL.",
                                                                  "timestamp": "2015-01-27T22:54:02Z",
                                                                  "features": [
                                                                    {
                                                                      "type": "Feature",
                                                                      "id": "node/2016217939",
                                                                      "properties": {
                                                                        "@id": "node/2016217939",
                                                                        "amenity": "clinic",
                                                                        "health_facility:referals": "AMREF",
                                                                        "health_facility:type": "health_center",
                                                                        "medical_service:general_medical_services": "yes",
                                                                        "medical_service:outpatient": "yes",
                                                                        "medical_service:pregnancy_test": "yes",
                                                                        "name": "Vostrum",
                                                                        "opening_hours": "24/7",
                                                                        "operational_status": "operational",
                                                                        "operator:type": "N/A"
                                                                      },
                                                                      "geometry": {
                                                                        "type": "Point",
                                                                        "coordinates": [
                                                                          36.781119,
                                                                          -1.3077519
                                                                        ]
                                                                      }
                                                                    },
                                                                	{
                                                                      "type": "Feature",
                                                                      "id": "node/701794660",
                                                                      "properties": {
                                                                        "@id": "node/701794660",
                                                                        "amenity": "hospital",
                                                                        "health_facility:bed": "14",
                                                                        "health_facility:exam_room": "yes",
                                                                        "health_facility:patients_per_day": "many",
                                                                        "health_facility:referals": "AMREF,Mbagathi,Kenyatta National Hospital",
                                                                        "health_facility:type": "health_center",
                                                                        "medical_service:antenatal_care": "yes",
                                                                        "medical_service:antiretroviral_therapy": "yes",
                                                                        "medical_service:basic_emergency_obsteric_care": "yes",
                                                                        "medical_service:circumcision": "yes",
                                                                        "medical_service:condom_distribution": "yes",
                                                                        "medical_service:disease_support_groups": "Blood Sugar",
                                                                        "medical_service:family_planning": "yes",
                                                                        "medical_service:gender_based_violence_services": "yes",
                                                                        "medical_service:general_medical_services": "yes",
                                                                        "medical_service:growth_and_nutritional_support": "yes",
                                                                        "medical_service:home_based_care": "yes",
                                                                        "medical_service:immunizations": "yes",
                                                                        "medical_service:inpatient": "yes",
                                                                        "medical_service:integrated_management_of_childhood_illness": "yes",
                                                                        "medical_service:malaria": "yes",
                                                                        "medical_service:minor_surgery": "yes",
                                                                        "medical_service:outpatient": "yes",
                                                                        "medical_service:pmtct": "yes",
                                                                        "medical_service:pregnancy_test": "yes",
                                                                        "medical_service:psychosocial_support_counselling": "yes",
                                                                        "medical_service:sexually_transmitted_infections_management": "yes",
                                                                        "medical_service:tb_diagnosis": "yes",
                                                                        "medical_service:tb_labs": "yes",
                                                                        "medical_service:tb_treatment": "yes",
                                                                        "medical_service:vct_hiv_counselling_test": "yes",
                                                                        "medical_service:youth_friendly_services": "yes",
                                                                        "medical_staff:clinical_officer": "2",
                                                                        "medical_staff:community_pharmacist": "2",
                                                                        "medical_staff:counsellor": "2",
                                                                        "medical_staff:general_practitioner": "1",
                                                                        "medical_staff:lab_tech": "2",
                                                                        "medical_staff:medical_officer": "1",
                                                                        "medical_staff:midwife": "2",
                                                                        "medical_staff:nurse": "2",
                                                                        "medical_staff:pharm_tech": "2",
                                                                        "name": "Ushirika",
                                                                        "opening_hours": "24/7",
                                                                        "operational_status": "operational",
                                                                        "operational_status:electricity": "always",
                                                                        "operator:type": "ngo_cbo"
                                                                      },
                                                                      "geometry": {
                                                                        "type": "Point",
                                                                        "coordinates": [
                                                                          36.7727571,
                                                                          -1.3077798
                                                                        ]
                                                                      }
                                                                    },
                                                                    {
                                                                      "type": "Feature",
                                                                      "id": "node/671166105",
                                                                      "properties": {
                                                                        "@id": "node/671166105",
                                                                        "amenity": "hospital",
                                                                        "health_facility:bed": "5",
                                                                        "health_facility:cot": "14",
                                                                        "health_facility:exam_room": "yes",
                                                                        "health_facility:patients_per_day": "100",
                                                                        "health_facility:referals": "IDH,KNH",
                                                                        "health_facility:type": "health_center",
                                                                        "medical_service:antenatal_care": "yes",
                                                                        "medical_service:antiretroviral_therapy": "yes",
                                                                        "medical_service:circumcision": "yes",
                                                                        "medical_service:comprehensive_essential_obsteric_care": "yes",
                                                                        "medical_service:condom_distribution": "yes",
                                                                        "medical_service:family_planning": "yes",
                                                                        "medical_service:gender_based_violence_services": "yes",
                                                                        "medical_service:general_medical_services": "yes",
                                                                        "medical_service:growth_and_nutritional_support": "yes",
                                                                        "medical_service:health_insurance": "no",
                                                                        "medical_service:home_based_care": "yes",
                                                                        "medical_service:immunizations": "yes",
                                                                        "medical_service:inpatient": "yes",
                                                                        "medical_service:integrated_management_of_childhood_illness": "yes",
                                                                        "medical_service:malaria": "yes",
                                                                        "medical_service:minor_surgery": "yes",
                                                                        "medical_service:outpatient": "yes",
                                                                        "medical_service:palliative_care": "yes",
                                                                        "medical_service:pmtct": "yes",
                                                                        "medical_service:pregnancy_test": "yes",
                                                                        "medical_service:prevention": "HIV",
                                                                        "medical_service:psychosocial_support_counselling": "yes",
                                                                        "medical_service:sexually_transmitted_infections_management": "yes",
                                                                        "medical_service:tb_diagnosis": "yes",
                                                                        "medical_service:tb_labs": "yes",
                                                                        "medical_service:tb_treatment": "yes",
                                                                        "medical_service:vct_hiv_counselling_test": "yes",
                                                                        "medical_service:youth_friendly_services": "yes",
                                                                        "medical_staff:clinical_officer": "5",
                                                                        "medical_staff:counsellor": "2",
                                                                        "medical_staff:general_practitioner": "1",
                                                                        "medical_staff:lab_tech": "2",
                                                                        "medical_staff:medical_officer": "5",
                                                                        "medical_staff:midwife": "7",
                                                                        "medical_staff:nurse": "6",
                                                                        "medical_staff:pharmacist": "4",
                                                                        "name": "AMREF",
                                                                        "opening_hours": "Mo-Fr 08:00-16:30",
                                                                        "operational_status": "operational",
                                                                        "operational_status:electricity": "always",
                                                                        "operator:type": "ngo_international"
                                                                      },
                                                                      "geometry": {
                                                                        "type": "Point",
                                                                        "coordinates": [
                                                                          36.7956417,
                                                                          -1.311196
                                                                        ]
                                                                      }
                                                                    }
                                                                ]
                                                                }
                                                                })
                                                                );

                                                                var alliedVectorLayer = new ol.layer.Vector({
                                                                                              source: alliedVectorSource,
                                                                                              style: alliedStyleFunction
                                                                                            });

                                                                                            map.addLayer(alliedVectorLayer);



                                                                var vectorSource = new ol.source.Vector({
                                                                  features: [iconFeature]
                                                                });

                                                                var vectorLayer = new ol.layer.Vector({
                                                                  source: vectorSource
                                                                });

                                                                map.addLayer(vectorLayer);

                                                                map.on('singleclick', function(evt) {

                                                                  var coordinate = evt.coordinate;
                            									  //coordinate = ol.proj.transform(coordinate, 'EPSG:3857', 'EPSG:4326')
                                                                  console.log(coordinate);
                                                                  //console.log(ol.proj.transform(coordinate, 'EPSG:4326', 'EPSG:3857'));
                            									  //console.log(ol.proj.transform(coordinate, 'EPSG:3857', 'EPSG:4326'));
                                                                  document.getElementById('personAddress.latitude').value = coordinate[0];
                                                                  document.getElementById('personAddress.longitude').value = coordinate[1];
                                                                    iconFeature = new ol.Feature({
                                                                      geometry: new ol.geom.Point(coordinate),
                                                                      name: 'You live here'
                                                                    });
                                                                    map.removeLayer(vectorLayer);

                                                                    iconFeature.setStyle(iconStyle);

                                                                    vectorSource = new ol.source.Vector({
                                                                      features: [iconFeature]
                                                                    });

                                                                    vectorLayer = new ol.layer.Vector({
                                                                      source: vectorSource
                                                                    });

                                                                    map.addLayer(vectorLayer);
                                                                });

                            										/*
                            									map.on("pointermove", function (evt) {
                            											var hit = this.forEachFeatureAtPixel(evt.pixel,
                            													function(feature, layer) {
                            														return true;
                            													});
                            											if (hit) {
                            												var feature = map.forEachFeatureAtPixel(evt.pixel, function(feature, layer)
                            												{
                            													return feature;
                            												});

                            												var geometry = feature.getGeometry();
                            												var coord = geometry.getCoordinates();
                            												var content = '';
                            												if (feature.get('amenity') == 'Dwelling')
                            												{
                            													content = '<p><code>' + feature.get('name') + '</code></p>';
                            												}
                            												else
                            												{
                            													content = '<p><code>' + feature.get('name') + '</code></p>';
                            													;
                            												}
                            												popup.setPosition(coord);
                            												$(element).popover({
                            												  'placement': 'top',
                            												  'html': true,
                            												  'content': content
                            												});
                            												$(element).popover('show');
                            											} else {
                            												$(element).popover('destroy');
                            											}
                            										});*/
                                                                ////////////////////////////////////////////////////////////////////////////////////
                                                            </script>
			</spring:nestedPath>
		</td>
	</tr>
	
	<c:forEach var="relationshipMap" items="${relationshipsMap}">
		<c:choose>
			<c:when test="${fn:contains(relationshipMap.key, 'a')}" >
				<tr class="parentTableRow">
					<th class="headerCell">
						${relationshipMap.value.relationshipType.aIsToB}
					</th>
					<td class="inputCell">						
						<openmrs_tag:personField formFieldName="${relationshipMap.key}" searchLabelCode="Person.find" initialValue="${relationshipMap.value.personA.personId}" linkUrl="" callback="" canAddNewPerson="true" />
					</td>
				</tr>
			</c:when>
			<c:otherwise>
				<tr class="parentTableRow">
					<th class="headerCell">
						${relationshipMap.value.relationshipType.bIsToA}
					</th>
					<td class="inputCell">
						<openmrs_tag:personField formFieldName="${relationshipMap.key}" searchLabelCode="Person.find" initialValue="${relationshipMap.value.personB.personId}" linkUrl="" callback="" canAddNewPerson="true"/>
					</td>
				</tr>	
			</c:otherwise>
		</c:choose>
	</c:forEach>
	
	<c:forEach var="personAttribute" items="${patientModel.personAttributes}" varStatus="varStatus">	
		<c:set var="authorized" value="false" />
		<c:choose>
			<c:when test="${not empty personAttribute.attributeType.editPrivilege}">
				<openmrs:hasPrivilege privilege="${personAttribute.attributeType.editPrivilege.privilege}">
					<c:set var="authorized" value="true" />
				</openmrs:hasPrivilege>
			</c:when>
			<c:otherwise>
				<c:set var="authorized" value="true" />
			</c:otherwise>
		</c:choose>
		
		<tr class="parentTableRow">
			<th class="headerCell"><openmrs:message code="PersonAttributeType.${fn:replace(personAttribute.attributeType.name, ' ', '')}" text="${personAttribute.attributeType.name}"/></th>
			<td class="inputCell">
				<c:choose>
					<c:when test="${authorized == true}">
						<spring:nestedPath path="personAttributes[${varStatus.index}]">
						<spring:bind path="personAttributeId">
							<input type="hidden" name="${status.expression}" value="${status.value}"/>
						</spring:bind>
						<spring:bind path="value">
						<openmrs:fieldGen 
							type="${personAttribute.attributeType.format}" 
							formFieldName="${status.expression}"
							val="${personAttribute.hydratedObject}" 
							parameters="optionHeader=[blank]|showAnswers=${personAttribute.attributeType.foreignKey}|isNullable=false" /> <%-- isNullable=false so booleans don't have 'unknown' radiobox --%>
						</spring:bind>
						</spring:nestedPath>
					</c:when>					
				</c:choose>
			</td>
		</tr>	
	</c:forEach>
	<tr class="parentTableRow">
		<th class="headerCell lastCell"><openmrs:message code="Person.dead"/></th>
		<td class="inputCell lastCell">
			<openmrs:message code="Person.dead.checkboxInstructions"/>
			<spring:bind path="patient.dead">
				<input type="hidden" name="_${status.expression}"/>
				<input type="checkbox" name="${status.expression}" 
					   <c:if test="${status.value == true}">checked</c:if>
					   onclick="personDeadClicked(this)" id="personDead"
				/>
				<c:if test="${status.errorMessage != ''}"><span class="error">${status.errorMessage}</span></c:if>
			</spring:bind>
			<script type="text/javascript">
				function personDeadClicked(input) {
					if (input.checked) {
						document.getElementById("deathInformation").style.display = "";
					}
					else {
						document.getElementById("deathInformation").style.display = "none";
						document.getElementById("deathDate").value = "";
						var cause = document.getElementById("causeOfDeath");
						if (cause != null)
							cause.value = "";
					}
				}
			</script>
			<br/>
			
			<div id="deathInformation">
				<b><openmrs:message code="Person.deathDate"/>:</b>

				<spring:bind path="patient.deathDate">
					<input type="text" name="${status.expression}" size="10" 
						   value="${status.value}" onFocus="showCalendar(this)"
						   id="deathDate" />
					<i style="font-weight: normal; font-size: 0.8em;">(<openmrs:message code="general.format"/>: <openmrs:datePattern />)</i>
					<c:if test="${status.errorMessage != ''}"><span class="error">${status.errorMessage}</span></c:if>
				</spring:bind>
				&nbsp; &nbsp;

				<openmrs:message code="Person.deathdateEstimated"/>
				<spring:bind path="patient.deathdateEstimated">
					<input type="hidden" name="_${status.expression}"> 
                    <input type="checkbox" name="${status.expression}" value="true"
						<c:if test="${status.value == true}">checked</c:if> 
						   id="deathdateEstimatedInput" 
					 />
					<c:if test="${status.errorMessage != ''}"><span class="error">${status.errorMessage}</span></c:if>
				</spring:bind>
				&nbsp; 
				
				<openmrs:message code="Person.causeOfDeath"/>
				<openmrs:globalProperty key="concept.causeOfDeath" var="conceptCauseOfDeath" />
				<openmrs:globalProperty key="concept.otherNonCoded" var="conceptOther" />
				<spring:bind path="patient.causeOfDeath">
					<openmrs:fieldGen type="org.openmrs.Concept" formFieldName="${status.expression}" val="${status.value}" parameters="showAnswers=${conceptCauseOfDeath}|showOther=${conceptOther}|otherValue=${causeOfDeathOther}" />
					<%--<input type="text" name="causeOfDeath" value="${status.value}" id="causeOfDeath"/>--%>
					<c:if test="${status.errorMessage != ''}"><span class="error">${status.errorMessage}</span></c:if>
				</spring:bind>
				
				<script type="text/javascript">				
					//set up death info fields
					personDeadClicked(document.getElementById("personDead"));
				</script>
			</div>
		</td>
	</tr>
	</table>
	
	<input type="hidden" name="patientId" value="<c:out value="${param.patientId}" />" />
	
	<br />
	<input type="submit" value="<openmrs:message code="general.save" />" name="action" id="addButton"> &nbsp; &nbsp; 
	<input type="button" value="<openmrs:message code="general.back" />" onclick="history.go(-1);">	
</form:form>

<script type="text/javascript">
	updateAge();
	var idT = document.getElementById('identifiers0.identifierType');
	var idTi = idT.options[idT.selectedIndex].value;
	toggleLocationBoxAndIndentifierTypeWarning(idTi,'initialLocationBox0',0);

</script>

<%@ include file="/WEB-INF/template/footer.jsp" %>
