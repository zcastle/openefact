<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:regexp="http://exslt.org/regular-expressions"
  xmlns:gemfunc="http://www.sunat.gob.pe/gem/functions"
  xmlns="urn:sunat:names:specification:ubl:peru:schema:xsd:SummaryDocuments-1"
  xmlns:ds="http://www.w3.org/2000/09/xmldsig#"
  xmlns:func="http://exslt.org/functions"
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
  <!-- xsl:include href="../../../commons/error/error_utils.xsl" dp:ignore-multiple="yes" /-->
	<xsl:include href="local:///commons/error/error_utils.xsl" dp:ignore-multiple="yes" />
    	
  <!-- key Numero de lineas duplicados fin -->
  <xsl:key name="by-invoiceLine-id" match="*[local-name()='SummaryDocuments']/sac:SummaryDocumentsLine" use="cbc:LineID"/>
  
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
        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'1004'" /> <xsl:with-param name="errorMessage" select="'Error resumen de boletas'" /> </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test="not(./cbc:InvoiceTypeCode = 'RC')">
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'1003'" /> <xsl:with-param name="errorMessage" select="'Error resumen de boletas'" /> </xsl:call-template>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose-->
    
    <!-- 2.- Número del Documento del emisor - Nro RUC --> <!-- <xsl:value-of select="./cac:AccountingSupplierParty/cbc:CustomerAssignedAccountID"/> -->
    <xsl:choose>
      <xsl:when test="not(string(./cac:AccountingSupplierParty/cbc:CustomerAssignedAccountID))">
        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2217'" /> <xsl:with-param name="errorMessage" select="'Error resumen de boletas'" /> </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test='not(regexp:match(./cac:AccountingSupplierParty/cbc:CustomerAssignedAccountID,"^[0-9]{11}$"))'>
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2216'" /> <xsl:with-param name="errorMessage" select="'Error resumen de boletas'" /> </xsl:call-template>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
          
    <!-- 3.- Numeracion, conformada por serie y número correlativo --> <!-- <xsl:value-of select="./cbc:ID"/> -->
    <xsl:choose>
      <xsl:when test="not(string(./cbc:ID))">
        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2211'" /> <xsl:with-param name="errorMessage" select="'Error resumen de boletas'" /> </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test='not(regexp:match(./cbc:ID,"[R][C]-[0-9]{8}-[0-9]{1,5}"))'>
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2210'" /> <xsl:with-param name="errorMessage" select="'Error resumen de boletas'" /> </xsl:call-template>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
          
    <!-- 4.- Version de la Estructura del Documento --> <!-- <xsl:value-of select="./cbc:CustomizationID"/> -->
    <xsl:choose>
      <xsl:when test="not(string(./cbc:CustomizationID))">
        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2073'" /> <xsl:with-param name="errorMessage" select="'Error resumen de boletas'" /> </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test='not(./cbc:CustomizationID="1.0")'>
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2072'" /> <xsl:with-param name="errorMessage" select="'Error resumen de boletas'" /> </xsl:call-template>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
          
    <!-- 5.- Version del UBL --> <!-- <xsl:value-of select="./cbc:UBLVersionID"/> -->
    <xsl:choose>
      <xsl:when test="not(string(./cbc:UBLVersionID))">
        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2075'" /> <xsl:with-param name="errorMessage" select="'Error resumen de boletas'" /> </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test='not(./cbc:UBLVersionID="2.0")'>
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2074'" /> <xsl:with-param name="errorMessage" select="'Error resumen de boletas'" /> </xsl:call-template>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
          
    <!-- 6.- Tipo de Documento del Emisor - RUC --> <!-- <xsl:value-of select="./cac:AccountingSupplierParty/cbc:AdditionalAccountID"/> -->
    <xsl:if test="not(string(./cac:AccountingSupplierParty/cbc:AdditionalAccountID))">
      <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2219'" /> <xsl:with-param name="errorMessage" select="'Error resumen de boletas'" /> </xsl:call-template>
    </xsl:if>
    <xsl:if test='not(regexp:match(./cac:AccountingSupplierParty/cbc:AdditionalAccountID,"^[6]{1}$"))'>
      <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2218'" /> <xsl:with-param name="errorMessage" select="'Error resumen de boletas'" /> </xsl:call-template>
    </xsl:if>
    
    <!-- 7.- Apellidos y nombres o denominacion o razon social Emisor --> <!-- <xsl:value-of select="./cac:AccountingSupplierParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName"/> -->
    <xsl:choose>
      <xsl:when test="not(string(./cac:AccountingSupplierParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName))">
        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2229'" /> <xsl:with-param name="errorMessage" select="'Error resumen de boletas'" /> </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test='not(regexp:match(./cac:AccountingSupplierParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName,"^[^\s].{1,100}"))'>
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2228'" /> <xsl:with-param name="errorMessage" select="'Error resumen de boletas'" /> </xsl:call-template>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
    
    <!-- 8.- Fecha de emision del documento --> <!-- <xsl:value-of select="./cbc:ReferenceDate"/> --> 
    <xsl:choose>
      <xsl:when test="(not(./cbc:ReferenceDate))">
        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2234'" /> <xsl:with-param name="errorMessage" select="'Error resumen de boletas'" /> </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test='not(regexp:match(./cbc:ReferenceDate,"^[0-9]{4}-[0-9]{2}-[0-9]{2}$"))'>
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2233'" /> <xsl:with-param name="errorMessage" select="'Error resumen de boletas'" /> </xsl:call-template>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
    
    <xsl:variable name="fechaEmisionDDMMYYYY" select='concat(substring(./cbc:ReferenceDate,9,2),"-",substring(./cbc:ReferenceDate,6,2),"-",substring(./cbc:ReferenceDate,1,4))'/>
    
    <xsl:if test='not(regexp:match($fechaEmisionDDMMYYYY,"^(?:(?:0?[1-9]|1\d|2[0-8])(\/|-)(?:0?[1-9]|1[0-2]))(\/|-)(?:[1-9]\d\d\d|\d[1-9]\d\d|\d\d[1-9]\d|\d\d\d[1-9])$|^(?:(?:31(\/|-)(?:0?[13578]|1[02]))|(?:(?:29|30)(\/|-)(?:0?[1,3-9]|1[0-2])))(\/|-)(?:[1-9]\d\d\d|\d[1-9]\d\d|\d\d[1-9]\d|\d\d\d[1-9])$|^(29(\/|-)0?2)(\/|-)(?:(?:0[48]00|[13579][26]00|[2468][048]00)|(?:\d\d)?(?:0[48]|[2468][048]|[13579][26]))$"))'>
      <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2235'" /> <xsl:with-param name="errorMessage" select="'Error resumen de boletas'" /> </xsl:call-template>
    </xsl:if>
    
    <xsl:variable name="fechaRangos" select="./cbc:ReferenceDate"/>
    <xsl:variable name="currentdate" select="date:date()"></xsl:variable>
    <xsl:if test="((substring-before(date:difference($currentdate, concat($fechaRangos,'-00:00')),'D') != 'P0') and (substring-before(date:difference($currentdate, concat($fechaRangos,'-00:00')),'P')  != substring-before('-P','P')))">
      <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2237'" /> <xsl:with-param name="errorMessage" select="'Error resumen de boletas'" /> </xsl:call-template>
    </xsl:if>
    
    <!-- 9.- Fecha de emision de comunicacion --> 
    <xsl:choose>
      <xsl:when test="(not(./cbc:IssueDate))">
        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2231'" /> <xsl:with-param name="errorMessage" select="'Error resumen de boletas'" /> </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test='not(regexp:match(./cbc:IssueDate,"^[0-9]{4}-[0-9]{2}-[0-9]{2}$"))'>
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2230'" /> <xsl:with-param name="errorMessage" select="'Error resumen de boletas'" /> </xsl:call-template>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
    
    <xsl:variable name="fechaEmisionComDDMMYYYY" select='concat(substring(./cbc:IssueDate,9,2),"-",substring(./cbc:IssueDate,6,2),"-",substring(./cbc:IssueDate,1,4))'/>
    
    <xsl:if test='not(regexp:match($fechaEmisionComDDMMYYYY,"^(?:(?:0?[1-9]|1\d|2[0-8])(\/|-)(?:0?[1-9]|1[0-2]))(\/|-)(?:[1-9]\d\d\d|\d[1-9]\d\d|\d\d[1-9]\d|\d\d\d[1-9])$|^(?:(?:31(\/|-)(?:0?[13578]|1[02]))|(?:(?:29|30)(\/|-)(?:0?[1,3-9]|1[0-2])))(\/|-)(?:[1-9]\d\d\d|\d[1-9]\d\d|\d\d[1-9]\d|\d\d\d[1-9])$|^(29(\/|-)0?2)(\/|-)(?:(?:0[48]00|[13579][26]00|[2468][048]00)|(?:\d\d)?(?:0[48]|[2468][048]|[13579][26]))$"))'>
      <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2232'" /> <xsl:with-param name="errorMessage" select="'Error resumen de boletas'" /> </xsl:call-template>
    </xsl:if>
    
    <xsl:variable name="issuedate" select="./cbc:IssueDate"/>
    <xsl:if test="(date:seconds(date:difference(concat($issuedate,'-00:00'),$currentdate)) &lt; 0)">
      <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2236'" /> <xsl:with-param name="errorMessage" select="'Error resumen de boletas'" /> </xsl:call-template>
    </xsl:if>
    <xsl:if test="(date:seconds(date:difference(concat($fechaRangos,'-00:00'),$issuedate)) &lt; 0)">
      <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'4036'" /> <xsl:with-param name="errorMessage" select="'Error resumen de boletas'" /> </xsl:call-template>
    </xsl:if>
    
    
    
    <!-- 10.- Firma del Documento -->
    <xsl:choose>
      <xsl:when test="not((cac:Signature/cbc:ID))">
        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2076'" /> <xsl:with-param name="errorMessage" select="'Error resumen de boletas'" /> </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test='not(regexp:match(cac:Signature/cbc:ID,"^(?!\s*$).{1,3000}"))'>
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2077'" /> <xsl:with-param name="errorMessage" select="'Error resumen de boletas'" /> </xsl:call-template>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
   
    <xsl:if test="not(cac:Signature/cac:SignatoryParty/cac:PartyIdentification/cbc:ID)">
      <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2079'" /> <xsl:with-param name="errorMessage" select="'Error resumen de boletas'" /> </xsl:call-template>
    </xsl:if>
    <!-- xsl:if test="(cac:Signature/cac:SignatoryParty/cac:PartyIdentification/cbc:ID != cac:AccountingSupplierParty/cbc:CustomerAssignedAccountID)">
      <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2078'" /> <xsl:with-param name="errorMessage" select="'Error resumen de boletas'" /> </xsl:call-template>
    </xsl:if -->
   
    <xsl:choose>
      <xsl:when test="not(cac:Signature/cac:SignatoryParty/cac:PartyName/cbc:Name)">
         <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2081'" /> <xsl:with-param name="errorMessage" select="'Error resumen de boletas'" /> </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test='not(regexp:match(cac:Signature/cac:SignatoryParty/cac:PartyName/cbc:Name,"^[^\s].{1,100}"))'>
           <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2080'" /> <xsl:with-param name="errorMessage" select="'Error resumen de boletas'" /> </xsl:call-template>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
   
    <xsl:if test="not(cac:Signature/cac:DigitalSignatureAttachment/cac:ExternalReference/cbc:URI)">
      <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2083'" /> <xsl:with-param name="errorMessage" select="'Error resumen de boletas'" /> </xsl:call-template>
    </xsl:if>

    <xsl:choose>
      <xsl:when test="not((ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/ds:Signature/@Id))">
        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2085'" /> <xsl:with-param name="errorMessage" select="'Error resumen de boletas'" /> </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test='not(regexp:match(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/ds:Signature/@Id,"^[^\s].{1,100}"))'>
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2084'" /> <xsl:with-param name="errorMessage" select="'Error resumen de boletas'" /> </xsl:call-template>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
     
    <xsl:choose>
      <xsl:when test="not(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/ds:Signature/ds:SignedInfo/ds:CanonicalizationMethod/@Algorithm)">
        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2087'" /> <xsl:with-param name="errorMessage" select="'Error resumen de boletas'" /> </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test='not(regexp:match(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/ds:Signature/ds:SignedInfo/ds:CanonicalizationMethod/@Algorithm,"^[^\s].{1,100}"))'>
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2086'" /> <xsl:with-param name="errorMessage" select="'Error resumen de boletas'" /> </xsl:call-template>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
     
    <xsl:choose>
      <xsl:when test="not(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/ds:Signature/ds:SignedInfo/ds:SignatureMethod/@Algorithm)">
        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2089'" /> <xsl:with-param name="errorMessage" select="'Error resumen de boletas'" /> </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test='not(regexp:match(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/ds:Signature/ds:SignedInfo/ds:SignatureMethod/@Algorithm,"^[^\s].{1,100}"))'>
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2088'" /> <xsl:with-param name="errorMessage" select="'Error resumen de boletas'" /> </xsl:call-template>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
     
    <xsl:choose>
      <xsl:when test="not(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/ds:Signature/ds:SignedInfo/ds:Reference/@URI)">
        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2091'" /> <xsl:with-param name="errorMessage" select="'Error resumen de boletas'" /> </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test='string(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/ds:Signature/ds:SignedInfo/ds:Reference/@URI)'>
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2090'" /> <xsl:with-param name="errorMessage" select="'Error resumen de boletas'" /> </xsl:call-template>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
     
    <xsl:choose>
      <xsl:when test="not(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/ds:Signature/ds:SignedInfo/ds:Reference/ds:Transforms/ds:Transform/@Algorithm)">
        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2093'" /> <xsl:with-param name="errorMessage" select="'Error resumen de boletas'" /> </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test='not(regexp:match(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/ds:Signature/ds:SignedInfo/ds:Reference/ds:Transforms/ds:Transform/@Algorithm,"^[^\s].{1,100}"))'>
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2092'" /> <xsl:with-param name="errorMessage" select="'Error resumen de boletas'" /> </xsl:call-template>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
     
    <xsl:choose>
      <xsl:when test="not(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/ds:Signature/ds:SignedInfo/ds:Reference/ds:DigestMethod/@Algorithm)">
        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2095'" /> <xsl:with-param name="errorMessage" select="'Error resumen de boletas'" /> </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test='not(regexp:match(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/ds:Signature/ds:SignedInfo/ds:Reference/ds:DigestMethod/@Algorithm,"^[^\s].{1,100}"))'>
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2094'" /> <xsl:with-param name="errorMessage" select="'Error resumen de boletas'" /> </xsl:call-template>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
     
    <xsl:choose>
      <xsl:when test="not(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/ds:Signature/ds:SignedInfo/ds:Reference/ds:DigestValue)">
        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2097'" /> <xsl:with-param name="errorMessage" select="'Error resumen de boletas'" /> </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <!--
        <xsl:if test='not(regexp:match(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/ds:Signature/ds:SignedInfo/ds:Reference/ds:DigestValue,"^[^\s].{1,100}"))'>
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2096'" /> <xsl:with-param name="errorMessage" select="'Error resumen de boletas'" /> </xsl:call-template>
        </xsl:if>
        -->
      </xsl:otherwise>
    </xsl:choose>
     
    <xsl:choose>
      <xsl:when test="not(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/ds:Signature/ds:SignatureValue)">
        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2099'" /> <xsl:with-param name="errorMessage" select="'Error resumen de boletas'" /> </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test='not(regexp:match(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/ds:Signature/ds:SignatureValue,"[A-Za-z0-9+/=\s]{100,}"))'>
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2098'" /> <xsl:with-param name="errorMessage" select="'Error resumen de boletas'" /> </xsl:call-template>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
     
    <xsl:choose>
      <xsl:when test="not(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/ds:Signature/ds:KeyInfo/ds:X509Data/ds:X509Certificate)">
        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2101'" /> <xsl:with-param name="errorMessage" select="'Error resumen de boletas'" /> </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test='not(regexp:match(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/ds:Signature/ds:KeyInfo/ds:X509Data/ds:X509Certificate,"[A-Za-z0-9+/=\s]{100,}"))'>
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2100'" /> <xsl:with-param name="errorMessage" select="'Error resumen de boletas'" /> </xsl:call-template>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
    
    <xsl:if test="count(./sac:SummaryDocumentsLine) &lt; 1">
      <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2279'" /> <xsl:with-param name="errorMessage" select="'Error resumen de boletas'" /> </xsl:call-template>
    </xsl:if>
    
    <!-- Documentos del Resumen -->
	<xsl:for-each select="sac:SummaryDocumentsLine">
      <!-- 11.- Número de Fila -->
      
      <xsl:if test="count(key('by-invoiceLine-id', cbc:LineID)) > 1">
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2752'" /> <xsl:with-param name="errorMessage" select="concat('El numero de item esta duplicado: ', cbc:LineID)" /> </xsl:call-template>
      </xsl:if>
      
      <xsl:choose>
        <xsl:when test="not(regexp:match(./cbc:LineID,'[0-9]{1,}'))" >
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2238'" /> <xsl:with-param name="errorMessage" select="concat('Error en la linea: ', position())" /> </xsl:call-template>
        </xsl:when>
        <xsl:when test="not(string(cbc:LineID))" >
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2240'" /> <xsl:with-param name="errorMessage" select="concat('Error en la linea: ', ./cbc:LineID)" /> </xsl:call-template>
        </xsl:when>
        <xsl:when test="cbc:LineID &lt; 1">
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2239'" /> <xsl:with-param name="errorMessage" select="concat('Error en la linea: ', ./cbc:LineID)" /> </xsl:call-template>
        </xsl:when>
        <xsl:otherwise></xsl:otherwise>
      </xsl:choose>
      
      <!-- 12.- Tipo de Documento -->
      
      <xsl:choose>
        <xsl:when test="not(string(./cbc:DocumentTypeCode)) or gemfunc:is-blank(./cbc:DocumentTypeCode)">
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2242'" /> <xsl:with-param name="errorMessage" select="concat('Error en la linea: ', ./cbc:LineID)" /> </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <xsl:if test="not(./cbc:DocumentTypeCode='03' or ./cbc:DocumentTypeCode='07' or ./cbc:DocumentTypeCode='08')">
            <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2241'" /> <xsl:with-param name="errorMessage" select="concat('Error en la linea: ', ./cbc:LineID)" /> </xsl:call-template>
          </xsl:if>
        </xsl:otherwise>
      </xsl:choose>
    
      <!-- 13.- Numero de serie de los documentos --> 
      <xsl:choose>
        <xsl:when test="not(string(./sac:DocumentSerialID)) or gemfunc:is-blank(./sac:DocumentSerialID)">
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2244'" /> <xsl:with-param name="errorMessage" select="concat('Error en la linea: ', ./cbc:LineID)" /> </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <xsl:if test='not(regexp:match(./sac:DocumentSerialID,"[B][A-Z0-9]{3}"))'>
            <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2243'" /> <xsl:with-param name="errorMessage" select="concat('Error en la linea: ', ./cbc:LineID)" /> </xsl:call-template>
          </xsl:if>
        </xsl:otherwise>
      </xsl:choose>
      
      <!--14.- Número correlativo del documento de inicio dentro de la serie--> 
      <xsl:choose>
        <xsl:when test="not(string(./sac:StartDocumentNumberID)) or gemfunc:is-blank(./sac:StartDocumentNumberID)">
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2246'" /> <xsl:with-param name="errorMessage" select="concat('Error en la linea: ', ./cbc:LineID)" /> </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <xsl:if test='not(regexp:match(./sac:StartDocumentNumberID,"[0-9]{1,8}"))'>
            <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2245'" /> <xsl:with-param name="errorMessage" select="concat('Error en la linea: ', ./cbc:LineID)" /> </xsl:call-template>
          </xsl:if>
          <xsl:if test="./sac:StartDocumentNumberID &lt; 1">
            <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2249'" /> <xsl:with-param name="errorMessage" select="concat('Error en la linea: ', ./cbc:LineID)" /> </xsl:call-template>
          </xsl:if>
        </xsl:otherwise>
      </xsl:choose>
      
      <!--15.- Número correlativo del documento de fin dentro de la serie--> <!--<xsl:value-of select="./sac:StartDocumentNumberID"/>-<xsl:value-of select="./sac:EndDocumentNumberID"/>-->
      <xsl:choose>
        <xsl:when test="not(string(./sac:EndDocumentNumberID)) or gemfunc:is-blank(./sac:EndDocumentNumberID)">
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2248'" /> <xsl:with-param name="errorMessage" select="concat('Error en la linea: ', ./cbc:LineID)" /> </xsl:call-template>
        </xsl:when>
        <xsl:when test="./sac:StartDocumentNumberID &gt; ./sac:EndDocumentNumberID">
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2250'" /> <xsl:with-param name="errorMessage" select="concat('Error en la linea: ', ./cbc:LineID)" /> </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <xsl:if test='not(regexp:match(./sac:EndDocumentNumberID,"[0-9]{1,8}"))'>
            <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2247'" /> <xsl:with-param name="errorMessage" select="concat('Error en la linea: ', ./cbc:LineID)" /> </xsl:call-template>
          </xsl:if>
        </xsl:otherwise>
      </xsl:choose>
    
      <!--16.- Importe total de la venta, sesion en uso o del servicio prestado -->
      <xsl:if test="not(string(./sac:TotalAmount)) or gemfunc:is-blank(./sac:TotalAmount)">
        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2252'" /> <xsl:with-param name="errorMessage" select="concat('Error en la linea: ', ./cbc:LineID)" /> </xsl:call-template>
      </xsl:if>
      <xsl:if test='not(regexp:match(./sac:TotalAmount,"^[0-9]{1,12}(\.[0-9]{1,2})?$"))'>
        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2251'" /> <xsl:with-param name="errorMessage" select="concat('Error en la linea: ', ./cbc:LineID)" /> </xsl:call-template>
      </xsl:if>
      <xsl:if test="./sac:TotalAmount &lt; 0">
        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2253'" /> <xsl:with-param name="errorMessage" select="concat('Error en la linea: ', ./cbc:LineID)" /> </xsl:call-template>
      </xsl:if>
      
      <!--17.- Total valor de venta - operaciones gravadas -->
      <!--18.- Total valor de venta - operaciones inafectas -->
      <!--19.- Total valor de venta - operaciones exoneradas -->
      <xsl:choose>
        <xsl:when test="count(./sac:BillingPayment) &lt; 1">
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2259'" /> <xsl:with-param name="errorMessage" select="concat('Error en la linea: ', ./cbc:LineID)" /> </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <xsl:for-each select="./sac:BillingPayment">
            <xsl:if test="not(./cbc:InstructionID)">
              <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2257'" /> <xsl:with-param name="errorMessage" select="concat('Error en la linea: ', ./cbc:LineID)" /> </xsl:call-template>
            </xsl:if>
            <xsl:if test='not(./cbc:InstructionID="01" or ./cbc:InstructionID="02" or ./cbc:InstructionID="03" or ./cbc:InstructionID="04" or ./cbc:InstructionID="05")'>
              <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2256'" /> <xsl:with-param name="errorMessage" select="concat('Error en la linea: ', ./cbc:LineID)" /> </xsl:call-template>
            </xsl:if>
                          
            <xsl:if test="not(./cbc:PaidAmount)">
              <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2255'" /> <xsl:with-param name="errorMessage" select="concat('Error en la linea: ', ./cbc:LineID)" /> </xsl:call-template>
            </xsl:if>
            <xsl:if test="./cbc:PaidAmount &lt; 0">
              <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2260'" /> <xsl:with-param name="errorMessage" select="concat('Error en la linea: ', ./cbc:LineID)" /> </xsl:call-template>
            </xsl:if>
            <xsl:if test='not(regexp:match(./cbc:PaidAmount,"^[0-9]{1,12}(\.[0-9]{1,2})?$"))'>
              <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2254'" /> <xsl:with-param name="errorMessage" select="concat('Error en la linea: ', ./cbc:LineID)" /> </xsl:call-template>
            </xsl:if>
          </xsl:for-each>
                    
          <xsl:if test='count(./sac:BillingPayment/cbc:InstructionID[text()=01])>1'>
            <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2357'" /> <xsl:with-param name="errorMessage" select="concat('Error en la linea: ', ./cbc:LineID)" /> </xsl:call-template>
          </xsl:if>
          <xsl:if test='count(./sac:BillingPayment/cbc:InstructionID[text()=02])>1'>
            <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2358'" /> <xsl:with-param name="errorMessage" select="concat('Error en la linea: ', ./cbc:LineID)" /> </xsl:call-template>
          </xsl:if>
          <xsl:if test='count(./sac:BillingPayment/cbc:InstructionID[text()=03])>1'>
            <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2359'" /> <xsl:with-param name="errorMessage" select="concat('Error en la linea: ', ./cbc:LineID)" /> </xsl:call-template>
          </xsl:if>
          <xsl:if test='count(./sac:BillingPayment/cbc:InstructionID[text()=05])>1'>
            <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2424'" /> <xsl:with-param name="errorMessage" select="concat('Error en la linea: ', ./cbc:LineID)" /> </xsl:call-template>
          </xsl:if>
                          
          <!--xsl:if test='count(./sac:BillingPayment/cbc:InstructionID[text()=01])=0 or count(./sac:BillingPayment/cbc:InstructionID[text()=02])=0 or count(./sac:BillingPayment/cbc:InstructionID[text()=03])=0'>
            <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2357'" /> <xsl:with-param name="errorMessage" select="concat('Error en la linea: ', ./cbc:LineID)" /> </xsl:call-template>
          </xsl:if-->
        </xsl:otherwise>
      </xsl:choose>
      
      <!-- 20.- Importe total de sumatoria otros cargos del item -->
      <xsl:choose>
        <xsl:when test="count(./cac:AllowanceCharge) &lt; 1">
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2265'" /> <xsl:with-param name="errorMessage" select="concat('Error en la linea: ', ./cbc:LineID)" /> </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <xsl:for-each select="./cac:AllowanceCharge">
            <xsl:if test="not(./cbc:ChargeIndicator)">
              <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2264'" /> <xsl:with-param name="errorMessage" select="concat('Error en la linea: ', ./cbc:LineID)" /> </xsl:call-template>
            </xsl:if>
            <xsl:if test="not(./cbc:ChargeIndicator='true')">
              <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2263'" /> <xsl:with-param name="errorMessage" select="concat('Error en la linea: ', ./cbc:LineID)" /> </xsl:call-template>
            </xsl:if>
            
            <xsl:if test="not(./cbc:Amount)">
              <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2262'" /> <xsl:with-param name="errorMessage" select="concat('Error en la linea: ', ./cbc:LineID)" /> </xsl:call-template>
            </xsl:if>
            <xsl:if test='not(regexp:match(./cbc:Amount,"^[0-9]{1,12}(\.[0-9]{1,2})?$"))'>
              <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2261'" /> <xsl:with-param name="errorMessage" select="concat('Error en la linea: ', ./cbc:LineID)" /> </xsl:call-template>
            </xsl:if>
            <xsl:if test="not(./cbc:ChargeIndicator='true' and ./cbc:Amount &gt;= 0)">
              <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2266'" /> <xsl:with-param name="errorMessage" select="concat('Error en la linea: ', ./cbc:LineID)" /> </xsl:call-template>
            </xsl:if>
          </xsl:for-each>
        </xsl:otherwise>
      </xsl:choose>
      
      <xsl:if test="count(./cac:AllowanceCharge/cbc:ChargeIndicator[text()='true'])>1 or count(./cac:AllowanceCharge/cbc:ChargeIndicator[text()='false'])>1">
        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2411'" /> <xsl:with-param name="errorMessage" select="concat('Error en la linea: ', ./cbc:LineID)" /> </xsl:call-template>
      </xsl:if>
      
      <!-- 21.- Sumatoria IGV / ISC / Otros Tributos -->
      <!--
           bucle TaxTotal
				   Informacion acerca del importe total de un tipo particular de impuesto. 
				   Una repeticion por IGV, ISC,Otros Tributos.  
				   Valido la obligatoriedad de  IGV e ISC  pero no la de  otros  Tributos
      -->
      <xsl:choose>
        <xsl:when test="count(./cac:TaxTotal) &lt; 1">
          <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2277'" /> <xsl:with-param name="errorMessage" select="concat('Error en la linea: ', ./cbc:LineID)" /> </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <xsl:for-each select="./cac:TaxTotal">
            <xsl:if test="not(string(./cbc:TaxAmount))">
              <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2274'" /> <xsl:with-param name="errorMessage" select="concat('Error en la linea: ', ./cbc:LineID)" /> </xsl:call-template>
            </xsl:if>
    	      <xsl:if test='not(regexp:match(./cbc:TaxAmount,"^[0-9]{1,12}(\.[0-9]{1,2})?$"))'>
              <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2048'" /> <xsl:with-param name="errorMessage" select="concat('Error en la linea: ', ./cbc:LineID)" /> </xsl:call-template>
            </xsl:if>
            
            <xsl:if test="not(string(./cac:TaxSubtotal/cbc:TaxAmount))">
              <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2344'" /> <xsl:with-param name="errorMessage" select="concat('Error en la linea: ', ./cbc:LineID)" /> </xsl:call-template>
            </xsl:if>            
            <xsl:if test="not(regexp:match(./cac:TaxSubtotal/cbc:TaxAmount,'^[0-9]{1,12}(\.[0-9]{1,2})?$'))">
              <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2343'" /> <xsl:with-param name="errorMessage" select="concat('Error en la linea: ', ./cbc:LineID)" /> </xsl:call-template>
            </xsl:if>
            
            <xsl:if test="not(regexp:match(./cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID,'[0-9]{4}'))">
              <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2267'" /> <xsl:with-param name="errorMessage" select="concat('Error en la linea: ', ./cbc:LineID)" /> </xsl:call-template>
            </xsl:if>
            
            <xsl:if test="not(./cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID = '1000' or ./cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID = '2000' or ./cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID = '9999')">
              <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2268'" /> <xsl:with-param name="errorMessage" select="concat('Error en la linea: ', ./cbc:LineID)" /> </xsl:call-template>
            </xsl:if>
            
            <xsl:if test="not(./cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID)">
              <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2269'" /> <xsl:with-param name="errorMessage" select="concat('Error en la linea: ', ./cbc:LineID)" /> </xsl:call-template>
            </xsl:if>
            
            <xsl:if test="string-length(./cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID) &lt; 3">
              <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2270'" /> <xsl:with-param name="errorMessage" select="concat('Error en la linea: ', ./cbc:LineID)" /> </xsl:call-template>
            </xsl:if>
            
            <xsl:if test="./cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID = '1000' and not(./cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:Name = 'IGV')">
              <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2276'" /> <xsl:with-param name="errorMessage" select="concat('Error en la linea: ', ./cbc:LineID)" /> </xsl:call-template>
            </xsl:if>
            
            <xsl:if test="./cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID = '2000' and not(./cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:Name = 'ISC')">
              <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2275'" /> <xsl:with-param name="errorMessage" select="concat('Error en la linea: ', ./cbc:LineID)" /> </xsl:call-template>
            </xsl:if>
            
            <xsl:if test="not(./cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:Name)">
              <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2271'" /> <xsl:with-param name="errorMessage" select="concat('Error en la linea: ', ./cbc:LineID)" /> </xsl:call-template>
            </xsl:if>
          </xsl:for-each>
          
          <xsl:if test="count(./cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme[./cbc:Name='ISC']) &lt; 1 or count(./cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme[./cbc:Name='IGV']) &lt; 1">
            <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2278'" /> <xsl:with-param name="errorMessage" select="concat('Error en la linea: ', ./cbc:LineID)" /> </xsl:call-template>
          </xsl:if>
          
          <xsl:if test="count(./cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme[./cbc:ID='1000']) &gt; 1">
            <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2355'" /> <xsl:with-param name="errorMessage" select="concat('Error en la linea: ', ./cbc:LineID)" /> </xsl:call-template>
          </xsl:if>
          <xsl:if test="count(./cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme[./cbc:ID='2000']) &gt; 1">
            <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2356'" /> <xsl:with-param name="errorMessage" select="concat('Error en la linea: ', ./cbc:LineID)" /> </xsl:call-template>
          </xsl:if>
          <xsl:if test="count(./cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme[./cbc:ID='9999']) &gt; 1">
            <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2361'" /> <xsl:with-param name="errorMessage" select="concat('Error en la linea: ', ./cbc:LineID)" /> </xsl:call-template>
          </xsl:if>
        </xsl:otherwise>
      </xsl:choose>
      <!--/xsl:if-->
    </xsl:for-each>    
    
    
    <xsl:copy-of select="."/>
  </xsl:template>
  
    <func:function name="gemfunc:is-blank">
		<xsl:param name="data" select="''"/>
		<func:result select="regexp:match($data,'^[\s]*$')"/>
	</func:function>
  
</xsl:stylesheet>
