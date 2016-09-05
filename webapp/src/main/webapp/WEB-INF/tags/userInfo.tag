<%@ include file="/WEB-INF/template/include.jsp" %>

<%@ attribute name="infoType" required="true" %>

<c:if test="${infoType == 'location'}">
	${location}
</c:if>