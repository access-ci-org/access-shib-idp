<%@ page pageEncoding="UTF-8" %>
<%@ taglib uri="http://www.springframework.org/tags" prefix="spring" %>
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8">
    <title><spring:message code="root.title" text="Shibboleth IdP" /></title>
    <link rel="stylesheet" type="text/css" href="<%= request.getContextPath()%>/css/main.css">
  </head>

  <body>
    <div class="wrapper">
      <div class="container">
        <header>
          <img src="<%= request.getContextPath() %><spring:message code="idp.logo" />" alt="<spring:message code="idp.logo.alt-text" text="logo" />">
        </header>
    
        <div class="content">
          <div class="column one">
              <h2><spring:message code="root.message" text="No services are available at this location." /></h2>
              The ACCESS Identity Provider (IdP) has encountered an error with your
              request. This may be a temporary issue. You can try restarting your
              web browser to see if that fixes the issue. If you continue to
              experience problems, you can contact the ACCESS Help Desk.
            </div>
        </div>
      </div>

      <footer>
        <div class="container container-footer">
          <p class="footer-text"><spring:message code="root.footer" text="Insert your footer text here." /></p>
        </div>
      </footer>
    </div>

  </body>
</html>
