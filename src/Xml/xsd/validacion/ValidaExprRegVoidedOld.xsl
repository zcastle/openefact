<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:regexp="http://exslt.org/regular-expressions"
  xmlns="urn:oasis:names:specification:ubl:schema:xsd:Invoice-2"
  xmlns:ds="http://www.w3.org/2000/09/xmldsig#"
  xmlns:ext="urn:oasis:names:specification:ubl:schema:xsd:CommonExtensionComponents-2"
  xmlns:sac="urn:sunat:names:specification:ubl:peru:schema:xsd:SunatAggregateComponents-1"
  xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2"
  xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2"
  xmlns:dp="http://www.datapower.com/extensions"
  xmlns:fn="http://www.w3.org/2005/xpath-functions"
	xmlns:date="http://exslt.org/dates-and-times"
  extension-element-prefixes="dp"
  exclude-result-prefixes="dp"
  version="1.0">
  <!--xsl:include href="../../commons/error/error_utils.xsl" dp:ignore-multiple="yes" /-->
  <xsl:include href="local:///commons/error/error_utils.xsl" dp:ignore-multiple="yes" />

  <!-- key Numero de lineas duplicados fin -->
  <xsl:key name="by-invoiceLine-id" match="*[local-name()='VoidedDocuments']/sac:VoidedDocumentsLine" use="cbc:LineID"/>

  <xsl:template match="/*">
  
  	  	<xsl:variable name="numeroRuc" select="substring(dp:variable('var://context/cpe/nombreArchivoEnviado'), 1, 11)"/>
    	
    	<xsl:variable name="idFilename" select="substring(dp:variable('var://context/cpe/nombreArchivoEnviado'), 13, string-length(dp:variable('var://context/cpe/nombreArchivoEnviado')) - 16)"/>
    	
    	<xsl:variable name="fechaEnvioFile" select="substring(dp:variable('var://context/cpe/nombreArchivoEnviado'), 16, 8)"/>
    	
    	<!-- El RUC debe coincidir con el RUC del nombre del archivo -->
    	
    	<xsl:if test="$numeroRuc != cac:AccountingSupplierParty/cbc:CustomerAssignedAccountID">
            <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2221'" /> <xsl:with-param name="errorMessage" select="concat('ruc del xml diferente al nombre del archivo ', cac:AccountingSupplierParty/cbc:CustomerAssignedAccountID, ' diff ', $numeroRuc)" /> </xsl:call-template>
        </xsl:if>
        
		<!-- El ID debe coincidir con el nombre del archivo -->        
        <xsl:if test="$idFilename != cbc:ID">
            <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2220'" /> <xsl:with-param name="errorMessage" select="concat('id del xml diferente al id del nombre de archivo ', cbc:ID, ' diff ', $idFilename)" /> </xsl:call-template>
        </xsl:if>
        
		<!-- "2346" La fecha de generación del resumen debe ser igual a la fecha consignada en el nombre del archivo -->        
        <xsl:if test="$fechaEnvioFile != translate(cbc:IssueDate,'-','')">
            <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2346'" /> <xsl:with-param name="errorMessage" select="concat('fecha emision del xml diferente a la fecha de emision del nombre del archivo ', translate(cbc:IssueDate,'-',''), ' diff ', $fechaEnvioFile)" /> </xsl:call-template>
        </xsl:if>
        
  
    <!-- 1.- Tipo Comprobante --> 
    <!--xsl:choose>
      <xsl:when test="not(string(./cbc:InvoiceTypeCode))">
        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'1004'" /> <xsl:with-param name="errorMessage" select="'Error resumen de anulados'" /> </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test="not(./cbc:InvoiceTypeCode = 'RA')">
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'1003'" /> <xsl:with-param name="errorMessage" select="'Error resumen de anulados'" /> </xsl:call-template>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose-->
    
    <!-- 2.- Numero del Documento del emisor - Nro RUC --> 
    <xsl:choose>
      <xsl:when test="not(string(./cac:AccountingSupplierParty/cbc:CustomerAssignedAccountID))">
        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2217'" /> <xsl:with-param name="errorMessage" select="'Error resumen de anulados'" /> </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test='not(regexp:match(./cac:AccountingSupplierParty/cbc:CustomerAssignedAccountID,"^[0-9]{11}$"))'>
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2216'" /> <xsl:with-param name="errorMessage" select="'Error resumen de anulados'" /> </xsl:call-template>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
          
    <!-- 3.- Numeracion, conformada por serie y numero correlativo --> <!-- <xsl:value-of select="./cbc:ID"/> -->
    <xsl:choose>
      <xsl:when test="not(string(./cbc:ID))">
        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2284'" /> <xsl:with-param name="errorMessage" select="'Error resumen de anulados'" /> </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test='not(regexp:match(./cbc:ID,"[R][A]-[0-9]{8}-[0-9]{1,5}"))'>
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2283'" /> <xsl:with-param name="errorMessage" select="'Error resumen de anulados'" /> </xsl:call-template>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
          
    <!-- 4.- Version de la Estructura del Documento --> <!-- <xsl:value-of select="./cbc:CustomizationID"/> -->
    <xsl:choose>
      <xsl:when test="not(string(./cbc:CustomizationID))">
        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2073'" /> <xsl:with-param name="errorMessage" select="'Error resumen de anulados'" /> </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test='not(./cbc:CustomizationID="1.0")'>
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2072'" /> <xsl:with-param name="errorMessage" select="'Error resumen de anulados'" /> </xsl:call-template>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
          
    <!-- 5.- Version del UBL --> <!-- <xsl:value-of select="./cbc:UBLVersionID"/> -->
    <xsl:choose>
      <xsl:when test="not(string(./cbc:UBLVersionID))">
        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2075'" /> <xsl:with-param name="errorMessage" select="'Error resumen de anulados'" /> </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test='not(./cbc:UBLVersionID="2.0")'>
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2074'" /> <xsl:with-param name="errorMessage" select="'Error resumen de anulados'" /> </xsl:call-template>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
          
    <!-- 6.- Tipo de Documento del Emisor - RUC --> <!-- <xsl:value-of select="./cac:AccountingSupplierParty/cbc:AdditionalAccountID"/> -->
    <xsl:if test="not(string(./cac:AccountingSupplierParty/cbc:AdditionalAccountID))">
      <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2288'" /> <xsl:with-param name="errorMessage" select="'Error resumen de anulados'" /> </xsl:call-template>
    </xsl:if>
    <xsl:if test='not(regexp:match(./cac:AccountingSupplierParty/cbc:AdditionalAccountID,"^[6]{1}$"))'>
      <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2287'" /> <xsl:with-param name="errorMessage" select="'Error resumen de anulados'" /> </xsl:call-template>
    </xsl:if>
    
    <!-- 7.- Apellidos y nombres o denominacion o razon social Emisor --> <!-- <xsl:value-of select="./cac:AccountingSupplierParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName"/> -->
    <xsl:choose>
      <xsl:when test="not(string(./cac:AccountingSupplierParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName))">
        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2229'" /> <xsl:with-param name="errorMessage" select="'Error resumen de anulados'" /> </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test='not(regexp:match(./cac:AccountingSupplierParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName,"^[^\s].{1,100}"))'>
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2228'" /> <xsl:with-param name="errorMessage" select="'Error resumen de anulados'" /> </xsl:call-template>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
    
    <!-- 8.- Fecha de emision del documento --> <!-- <xsl:value-of select="./cbc:ReferenceDate"/> --> 
    <xsl:choose>
      <xsl:when test="(not(./cbc:ReferenceDate))">
        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2303'" /> <xsl:with-param name="errorMessage" select="'Error resumen de anulados'" /> </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test='not(regexp:match(./cbc:ReferenceDate,"^[0-9]{4}-[0-9]{2}-[0-9]{2}$"))'>
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2302'" /> <xsl:with-param name="errorMessage" select="'Error resumen de anulados'" /> </xsl:call-template>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
    
    <xsl:variable name="fechaEmisionDDMMYYYY" select='concat(substring(./cbc:ReferenceDate,9,2),"-",substring(./cbc:ReferenceDate,6,2),"-",substring(./cbc:ReferenceDate,1,4))'/>
    
    <xsl:if test='not(regexp:match($fechaEmisionDDMMYYYY,"^(?:(?:0?[1-9]|1\d|2[0-8])(\/|-)(?:0?[1-9]|1[0-2]))(\/|-)(?:[1-9]\d\d\d|\d[1-9]\d\d|\d\d[1-9]\d|\d\d\d[1-9])$|^(?:(?:31(\/|-)(?:0?[13578]|1[02]))|(?:(?:29|30)(\/|-)(?:0?[1,3-9]|1[0-2])))(\/|-)(?:[1-9]\d\d\d|\d[1-9]\d\d|\d\d[1-9]\d|\d\d\d[1-9])$|^(29(\/|-)0?2)(\/|-)(?:(?:0[48]00|[13579][26]00|[2468][048]00)|(?:\d\d)?(?:0[48]|[2468][048]|[13579][26]))$"))'>
      <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2304'" /> <xsl:with-param name="errorMessage" select="'Error resumen de anulados'" /> </xsl:call-template>
    </xsl:if>
    
    <xsl:variable name="fechaRangos" select="./cbc:ReferenceDate"/>
    <xsl:variable name="currentdate" select="date:date()"></xsl:variable>
    <!--xsl:if test="((substring-before(date:difference($currentdate, concat($fechaRangos,'-00:00')),'D') != 'P0') and (substring-before(date:difference($currentdate, concat($fechaRangos,'-00:00')),'P')  != substring-before('-P','P')))">
      <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2237'" /> <xsl:with-param name="errorMessage" select="'Error resumen de anulados'" /> </xsl:call-template>
    </xsl:if-->
    
    <!-- 9.- Fecha de emision de comunicacion --> 
    <xsl:choose>
      <xsl:when test="(not(./cbc:IssueDate))">
        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2299'" /> <xsl:with-param name="errorMessage" select="'Error resumen de anulados'" /> </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test='not(regexp:match(./cbc:IssueDate,"^[0-9]{4}-[0-9]{2}-[0-9]{2}$"))'>
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2298'" /> <xsl:with-param name="errorMessage" select="'Error resumen de anulados'" /> </xsl:call-template>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
    
    <xsl:variable name="fechaEmisionComDDMMYYYY" select='concat(substring(./cbc:IssueDate,9,2),"-",substring(./cbc:IssueDate,6,2),"-",substring(./cbc:IssueDate,1,4))'/>
    
    <xsl:if test='not(regexp:match($fechaEmisionComDDMMYYYY,"^(?:(?:0?[1-9]|1\d|2[0-8])(\/|-)(?:0?[1-9]|1[0-2]))(\/|-)(?:[1-9]\d\d\d|\d[1-9]\d\d|\d\d[1-9]\d|\d\d\d[1-9])$|^(?:(?:31(\/|-)(?:0?[13578]|1[02]))|(?:(?:29|30)(\/|-)(?:0?[1,3-9]|1[0-2])))(\/|-)(?:[1-9]\d\d\d|\d[1-9]\d\d|\d\d[1-9]\d|\d\d\d[1-9])$|^(29(\/|-)0?2)(\/|-)(?:(?:0[48]00|[13579][26]00|[2468][048]00)|(?:\d\d)?(?:0[48]|[2468][048]|[13579][26]))$"))'>
      <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2300'" /> <xsl:with-param name="errorMessage" select="'Error resumen de anulados'" /> </xsl:call-template>
    </xsl:if>
    
    <xsl:variable name="issuedate" select="./cbc:IssueDate"/>
    <xsl:if test="(date:seconds(date:difference(concat($issuedate,'-00:00'),$currentdate)) &lt; 0)">
      <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2301'" /> <xsl:with-param name="errorMessage" select="'Error resumen de anulados'" /> </xsl:call-template>
    </xsl:if>
    <xsl:if test="(date:seconds(date:difference(concat($fechaRangos,'-00:00'),$issuedate)) &lt; 0)">
      <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'4036'" /> <xsl:with-param name="errorMessage" select="'Error resumen de anulados'" /> </xsl:call-template>
    </xsl:if>
    
    
    <!-- 10.- Firma del Documento -->
<!--     <xsl:choose>
      <xsl:when test="not((cac:Signature/cbc:ID))">
        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2076'" /> <xsl:with-param name="errorMessage" select="'Error resumen de anulados'" /> </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test='not(regexp:match(cac:Signature/cbc:ID,"^(?!\s*$).{1,3000}"))'>
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2077'" /> <xsl:with-param name="errorMessage" select="'Error resumen de anulados'" /> </xsl:call-template>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
   
    <xsl:if test="not(cac:Signature/cac:SignatoryParty/cac:PartyIdentification/cbc:ID)">
      <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2079'" /> <xsl:with-param name="errorMessage" select="'Error resumen de anulados'" /> </xsl:call-template>
    </xsl:if>
    <xsl:if test="(cac:Signature/cac:SignatoryParty/cac:PartyIdentification/cbc:ID != cac:AccountingSupplierParty/cbc:CustomerAssignedAccountID)">
      <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2078'" /> <xsl:with-param name="errorMessage" select="'Error resumen de anulados'" /> </xsl:call-template>
    </xsl:if>
   
    <xsl:choose>
      <xsl:when test="not(cac:Signature/cac:SignatoryParty/cac:PartyName/cbc:Name)">
         <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2081'" /> <xsl:with-param name="errorMessage" select="'Error resumen de anulados'" /> </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test='not(regexp:match(cac:Signature/cac:SignatoryParty/cac:PartyName/cbc:Name,"^[^\s].{1,100}"))'>
           <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2080'" /> <xsl:with-param name="errorMessage" select="'Error resumen de anulados'" /> </xsl:call-template>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
   

      <xsl:if test="not(cac:Signature/cac:DigitalSignatureAttachment/cac:ExternalReference/cbc:URI)">
         <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2083'" /> <xsl:with-param name="errorMessage" select="'Error resumen de anulados'" /> </xsl:call-template>
      </xsl:if>
     
    <xsl:choose>
      <xsl:when test="not((ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/ds:Signature/@Id))">
        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2085'" /> <xsl:with-param name="errorMessage" select="'Error resumen de anulados'" /> </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test='not(regexp:match(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/ds:Signature/@Id,"^[^\s].{1,100}"))'>
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2084'" /> <xsl:with-param name="errorMessage" select="'Error resumen de anulados'" /> </xsl:call-template>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
     
    <xsl:choose>
      <xsl:when test="not(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/ds:Signature/ds:SignedInfo/ds:CanonicalizationMethod/@Algorithm)">
        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2087'" /> <xsl:with-param name="errorMessage" select="'Error resumen de anulados'" /> </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test='not(regexp:match(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/ds:Signature/ds:SignedInfo/ds:CanonicalizationMethod/@Algorithm,"^[^\s].{1,100}"))'>
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2086'" /> <xsl:with-param name="errorMessage" select="'Error resumen de anulados'" /> </xsl:call-template>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
     
    <xsl:choose>
      <xsl:when test="not(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/ds:Signature/ds:SignedInfo/ds:SignatureMethod/@Algorithm)">
        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2089'" /> <xsl:with-param name="errorMessage" select="'Error resumen de anulados'" /> </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test='not(regexp:match(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/ds:Signature/ds:SignedInfo/ds:SignatureMethod/@Algorithm,"^[^\s].{1,100}"))'>
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2088'" /> <xsl:with-param name="errorMessage" select="'Error resumen de anulados'" /> </xsl:call-template>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
     
    <xsl:choose>
      <xsl:when test="not(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/ds:Signature/ds:SignedInfo/ds:Reference/@URI)">
        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2091'" /> <xsl:with-param name="errorMessage" select="'Error resumen de anulados'" /> </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test='string(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/ds:Signature/ds:SignedInfo/ds:Reference/@URI)'>
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2090'" /> <xsl:with-param name="errorMessage" select="'Error resumen de anulados'" /> </xsl:call-template>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
     
    <xsl:choose>
      <xsl:when test="not(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/ds:Signature/ds:SignedInfo/ds:Reference/ds:Transforms/ds:Transform/@Algorithm)">
        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2093'" /> <xsl:with-param name="errorMessage" select="'Error resumen de anulados'" /> </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test='not(regexp:match(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/ds:Signature/ds:SignedInfo/ds:Reference/ds:Transforms/ds:Transform/@Algorithm,"^[^\s].{1,100}"))'>
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2092'" /> <xsl:with-param name="errorMessage" select="'Error resumen de anulados'" /> </xsl:call-template>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
     
    <xsl:choose>
      <xsl:when test="not(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/ds:Signature/ds:SignedInfo/ds:Reference/ds:DigestMethod/@Algorithm)">
        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2095'" /> <xsl:with-param name="errorMessage" select="'Error resumen de anulados'" /> </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test='not(regexp:match(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/ds:Signature/ds:SignedInfo/ds:Reference/ds:DigestMethod/@Algorithm,"^[^\s].{1,100}"))'>
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2094'" /> <xsl:with-param name="errorMessage" select="'Error resumen de anulados'" /> </xsl:call-template>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
     
    <xsl:choose>
      <xsl:when test="not(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/ds:Signature/ds:SignedInfo/ds:Reference/ds:DigestValue)">
        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2097'" /> <xsl:with-param name="errorMessage" select="'Error resumen de anulados'" /> </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>

      </xsl:otherwise>
    </xsl:choose>
     
    <xsl:choose>
      <xsl:when test="not(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/ds:Signature/ds:SignatureValue)">
        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2099'" /> <xsl:with-param name="errorMessage" select="'Error resumen de anulados'" /> </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test='not(regexp:match(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/ds:Signature/ds:SignatureValue,"[A-Za-z0-9+/=\s]{100,}"))'>
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2098'" /> <xsl:with-param name="errorMessage" select="'Error resumen de anulados'" /> </xsl:call-template>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
     
    <xsl:choose>
      <xsl:when test="not(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/ds:Signature/ds:KeyInfo/ds:X509Data/ds:X509Certificate)">
        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2101'" /> <xsl:with-param name="errorMessage" select="'Error resumen de anulados'" /> </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test='not(regexp:match(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/ds:Signature/ds:KeyInfo/ds:X509Data/ds:X509Certificate,"[A-Za-z0-9+/=\s]{100,}"))'>
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2100'" /> <xsl:with-param name="errorMessage" select="'Error resumen de anulados'" /> </xsl:call-template>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose> -->
    
    <!-- Documentos de la Baja -->
    <xsl:for-each select="sac:VoidedDocumentsLine">
      <!-- 11.- Numero de Fila -->
      
      <xsl:if test="count(key('by-invoiceLine-id', cbc:LineID)) > 1">
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2752'" /> <xsl:with-param name="errorMessage" select="concat('El numero de item esta duplicado: ', cbc:LineID)" /> </xsl:call-template>
      </xsl:if>
      
      <xsl:choose>
        <xsl:when test="not(regexp:match(./cbc:LineID,'^[0-9]{1,}?$'))" >
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2305'" /> <xsl:with-param name="errorMessage" select="'Error resumen de anulados'" /> </xsl:call-template>
        </xsl:when>
        <xsl:when test="not(string(cbc:LineID))" >
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2307'" /> <xsl:with-param name="errorMessage" select="'Error resumen de anulados'" /> </xsl:call-template>
        </xsl:when>
        <xsl:when test="cbc:LineID &lt; 1">
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2306'" /> <xsl:with-param name="errorMessage" select="'Error resumen de anulados'" /> </xsl:call-template>
        </xsl:when>
        <xsl:otherwise></xsl:otherwise>
      </xsl:choose>
      
      <!-- 12.- Tipo de Documento -->
      <xsl:choose>
        <xsl:when test="not(string(./cbc:DocumentTypeCode))">
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2309'" /> <xsl:with-param name="errorMessage" select="'Error resumen de anulados'" /> </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <xsl:if test="not(./cbc:DocumentTypeCode = '01' or ./cbc:DocumentTypeCode = '03' or ./cbc:DocumentTypeCode = '07' or ./cbc:DocumentTypeCode = '08')">
            <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2308'" /> <xsl:with-param name="errorMessage" select="'Error resumen de anulados'" /> </xsl:call-template>
          </xsl:if>
        </xsl:otherwise>
      </xsl:choose>
    
      <!-- 13.- Numero de serie de los documentos --> <!-- ./cbc:DocumentTypeCode = 01: FACTURA y 03: BOLETA -->
      <xsl:choose>
        <xsl:when test="not(string(./sac:DocumentSerialID))">
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2311'" /> <xsl:with-param name="errorMessage" select="'Error resumen de anulados'" /> </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <xsl:if test='not(regexp:match(./sac:DocumentSerialID,"^[B|F][A-Z0-9]{3}?$"))'>
            <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2310'" /> <xsl:with-param name="errorMessage" select="'Error resumen de anulados'" /> </xsl:call-template>
          </xsl:if>
          
          <xsl:if test="./cbc:DocumentTypeCode='01' and not(substring(./sac:DocumentSerialID,1,1)='F')">
            <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2345'" /> <xsl:with-param name="errorMessage" select="'Error resumen de anulados'" /> </xsl:call-template>
          </xsl:if>
          <xsl:if test="./cbc:DocumentTypeCode='03' and not(substring(./sac:DocumentSerialID,1,1)='B')">
            <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2345'" /> <xsl:with-param name="errorMessage" select="'Error resumen de anulados'" /> </xsl:call-template>
          </xsl:if>
        </xsl:otherwise>
      </xsl:choose>
      
      <!--14.- Numero correlativo del documento dado de baja --> 
      <xsl:choose>
        <xsl:when test="not(string(./sac:DocumentNumberID))">
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2313'" /> <xsl:with-param name="errorMessage" select="'Error resumen de anulados'" /> </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <xsl:if test='not(regexp:match(./sac:DocumentNumberID,"^[0-9]{1,8}?$"))'>
            <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2312'" /> <xsl:with-param name="errorMessage" select="'Error resumen de anulados'" /> </xsl:call-template>
          </xsl:if>
        </xsl:otherwise>
      </xsl:choose>
      
      <!--15.- Numero correlativo del documento de fin dentro de la serie--> <!--<xsl:value-of select="./sac:StartDocumentNumberID"/>-<xsl:value-of select="./sac:EndDocumentNumberID"/>-->
      <xsl:choose>
        <xsl:when test="not(string(./sac:VoidReasonDescription))">
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2315'" /> <xsl:with-param name="errorMessage" select="'Error resumen de anulados'" /> </xsl:call-template>
        </xsl:when>
        <xsl:when test="string-length(./sac:VoidReasonDescription) &lt; 3">
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2314'" /> <xsl:with-param name="errorMessage" select="'Error resumen de anulados'" /> </xsl:call-template>
        </xsl:when>
        <xsl:otherwise></xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
    
    <xsl:copy-of select="."/>
  </xsl:template>
</xsl:stylesheet>
