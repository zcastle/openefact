<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:regexp="http://exslt.org/regular-expressions"
	xmlns="urn:oasis:names:specification:ubl:schema:xsd:Invoice-2"
	xmlns:ds="http://www.w3.org/2000/09/xmldsig#"
	xmlns:ext="urn:oasis:names:specification:ubl:schema:xsd:CommonExtensionComponents-2"
	xmlns:sac="urn:sunat:names:specification:ubl:peru:schema:xsd:SunatAggregateComponents-1"
	xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2"
	xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2"
	xmlns:dp="http://www.datapower.com/extensions"
	extension-element-prefixes="dp" exclude-result-prefixes="dp" version="1.0"
	xmlns:date="http://exslt.org/dates-and-times">
	<!-- xsl:include href="../../../commons/error/error_utils.xsl" dp:ignore-multiple="yes" / -->
	<xsl:include href="local:///commons/error/error_utils.xsl" dp:ignore-multiple="yes" />

	<!-- Se aniade nuevo Template JS 091216-->
	<!-- <xsl:include href="local:///commons/checksum.xsl" dp:ignore-multiple="yes" /> -->
	
	<!-- key Documentos Relacionados Duplicados -->
	<xsl:key name="by-document-billing-reference" match="cac:BillingReference"
		use="concat(cac:InvoiceDocumentReference/cbc:DocumentTypeCode,' ', cac:InvoiceDocumentReference/cbc:ID)" />
	
	<xsl:key name="by-document-despatch-reference" match="cac:DespatchDocumentReference"
		use="concat(cbc:DocumentTypeCode,' ', cbc:ID)" />
	
	<xsl:key name="by-document-additional-reference" match="cac:AdditionalDocumentReference"
		use="concat(cbc:DocumentTypeCode,' ', cbc:ID)" />
	<!-- key Documentos Relacionados Duplicados fin -->
	
	<!-- key Numero de lineas duplicados fin -->
    <xsl:key name="by-invoiceLine-id" match="*[local-name()='Invoice']/cac:DebitNoteLine" use="cbc:ID"/>

	<xsl:key name="by-pricingReference-alternativeConditionPrice-priceTypeCode"
		match="./cac:PricingReference/cac:AlternativeConditionPrice" use="cbc:PriceTypeCode" />

	<xsl:template match="/*">
	
	<!-- Validando que el nombre del archivo coincida con la informacion enviada en el XML -->
    	
    	<xsl:variable name="numeroRuc" select="substring(dp:variable('var://context/cpe/nombreArchivoEnviado'), 1, 11)"/>
    	
    	<xsl:variable name="tipoComprobante" select="substring(dp:variable('var://context/cpe/nombreArchivoEnviado'), 13, 2)"/>
    	
    	<xsl:variable name="numeroSerie" select="substring(dp:variable('var://context/cpe/nombreArchivoEnviado'), 16, 4)"/>
    	
    	<xsl:variable name="numeroComprobante" select="substring(dp:variable('var://context/cpe/nombreArchivoEnviado'), 21, string-length(dp:variable('var://context/cpe/nombreArchivoEnviado')) - 24)"/>
    	
    	<!-- Numero de RUC del nombre del archivo no coincide con el consignado en el contenido del archivo XML -->
    	
    	<xsl:if test="$numeroRuc != cac:AccountingSupplierParty/cbc:CustomerAssignedAccountID">
            <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'1034'" /> <xsl:with-param name="errorMessage" select="concat('ruc del xml diferente al nombre del archivo ', cac:AccountingSupplierParty/cbc:CustomerAssignedAccountID, ' diff ', $numeroRuc)" /> </xsl:call-template>
        </xsl:if>
        
		<!-- Numero de Serie del nombre del archivo no coincide con el consignado en el contenido del archivo XML -->        
        <xsl:if test="$numeroSerie != substring(cbc:ID, 1, 4)">
            <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'1035'" /> <xsl:with-param name="errorMessage" select="concat('numero de serie del xml diferente al numero de serie del archivo ', substring(cbc:ID, 1, 4), ' diff ', $numeroSerie)" /> </xsl:call-template>
        </xsl:if>
        
		<!-- Numero de documento en el nombre del archivo no coincide con el consignado en el contenido del XML -->        
        <xsl:if test="$numeroComprobante != substring(cbc:ID, 6)">
            <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'1036'" /> <xsl:with-param name="errorMessage" select="concat('numero de comprobante del xml diferente al numero del archivo ', substring(cbc:ID, 6), ' diff ', $numeroComprobante)" /> </xsl:call-template>
        </xsl:if>
	
		<xsl:variable name="sacAdditionalInformation"
			select="ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/sac:AdditionalInformation" />

		<xsl:if test="count($sacAdditionalInformation)>1">
			<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2427'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND  (codigo: 2427)'" /> </xsl:call-template>
		</xsl:if>
		<!-- Numero del Documento del emisor - Nro RUC -->
		<xsl:choose>
			<xsl:when
				test="not(string(cac:AccountingSupplierParty/cbc:CustomerAssignedAccountID))">
				<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'1006'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 1006)'" /> </xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:if
					test='not(regexp:match(cac:AccountingSupplierParty/cbc:CustomerAssignedAccountID,"^[0-9]{11}$"))'>
					<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'1005'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 1005)'" /> </xsl:call-template>
				</xsl:if>
			</xsl:otherwise>
		</xsl:choose>

		<!-- Tipo de documento de identidad del emisor - siempre debe de ser RUC -->
		<xsl:if
			test="not(string(cac:AccountingSupplierParty/cbc:AdditionalAccountID))">
			<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'1008'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 1008)'" /> </xsl:call-template>
		</xsl:if>
		<xsl:if
			test='not(regexp:match(cac:AccountingSupplierParty/cbc:AdditionalAccountID,"^[6]{1}$"))'>
			<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'1007'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 1007)'" /> </xsl:call-template>
		</xsl:if>
		<xsl:if test="count(cac:AccountingSupplierParty/cbc:AdditionalAccountID)>1">
			<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2362'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2362)'" /> </xsl:call-template>
		</xsl:if>

		<!-- Numeracion, conformada por serie y numero correlativo -->
		<xsl:choose>
			<xsl:when test="not(string(cbc:ID))">
				<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'1002'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 1002)'" /> </xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:if test='not(regexp:match(cbc:ID,"^[FB][A-Z0-9]{3}-[0-9]{1,8}"))'>
					<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'1001'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 1001)'" /> </xsl:call-template>
				</xsl:if>
			</xsl:otherwise>
		</xsl:choose>

		<!-- Version de la Estructura del Documento -->
		<xsl:choose>
			<xsl:when test="not(string(cbc:CustomizationID))">
				<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2073'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2073)'" /> </xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:if
					test='not(regexp:match(cbc:CustomizationID,"^[0-9]{1,7}(\.[0-9]{1,2})?$"))'>
					<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2072'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2072)'" /> </xsl:call-template>
				</xsl:if>
			</xsl:otherwise>
		</xsl:choose>

		<!-- Version del UBL -->
		<xsl:choose>
			<xsl:when test="not(string(cbc:UBLVersionID))">
				<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2075'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2075)'" /> </xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:if test='not(regexp:match(cbc:UBLVersionID,"^[2]{1}(\.[0]{1})$"))'>
					<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2074'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2074)'" /> </xsl:call-template>
				</xsl:if>
			</xsl:otherwise>
		</xsl:choose>

		<!-- Fecha de emision -->
		<xsl:choose>
			<xsl:when test="(not(cbc:IssueDate))">
				<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'1010'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 1010)'" /> </xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:if
					test='not(regexp:match(cbc:IssueDate,"^[0-9]{4}-[0-9]{2}-[0-9]{2}$"))'>
					<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'1009'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 1009)'" /> </xsl:call-template>
				</xsl:if>
			</xsl:otherwise>
		</xsl:choose>

		<xsl:variable name="issuedate1" select="//cbc:IssueDate" />
		<xsl:variable name="currentdate" select="date:date()"></xsl:variable>
		<xsl:if
			test="((substring-before(date:difference($currentdate, concat($issuedate1,'-00:00')),'D') != 'P0') and (substring-before(date:difference($currentdate, concat($issuedate1,'-00:00')),'P')  != substring-before('-P','P')))">
			<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'1011'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 1011)'" /> </xsl:call-template>
		</xsl:if>

		<!-- Apellidos y nombres o denominacion o razon social Emisor -->
		<!-- modificado 27/01/2014 fin -->
		<xsl:choose>
			<xsl:when
				test="not(string(cac:AccountingSupplierParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName))">
				<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'1037'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 1037)'" /> </xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:if
					test='not(regexp:match(cac:AccountingSupplierParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName,"^(?!\s*$).{1,100}"))'>
					<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'1038'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 1038)'" /> </xsl:call-template>
				</xsl:if>
			</xsl:otherwise>
		</xsl:choose>
		<!-- modificado 27/01/2014 fin -->


<!-- Bloque Comentado 301116-->	
		<!-- Valida que el numerode documento del adquirente existe y si es RUC 
			valida que conste de 11 caracteres numericos -->
<!-- 		<xsl:choose>
			<xsl:when
				test="not(string(cac:AccountingCustomerParty/cbc:CustomerAssignedAccountID))">
				<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2014'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2014)'" /> </xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:if
					test="cac:AccountingCustomerParty/cbc:AdditionalAccountID[text()='6'] and not(regexp:match(cac:AccountingCustomerParty/cbc:CustomerAssignedAccountID,'^[0-9]{11}$|^[-]{1}$'))">
					<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2017'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2017)'" /> </xsl:call-template>
				</xsl:if>
			</xsl:otherwise>
		</xsl:choose> -->

		
		<!-- Valida que el numerode documento del adquirente existe y si es RUC 
			valida que conste de 11 caracteres numericos -->		
			<xsl:if
				test="not(string(cac:AccountingCustomerParty/cbc:CustomerAssignedAccountID))">
				<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2014'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2014)'" /> </xsl:call-template>
			</xsl:if>
			<xsl:if
				test="cac:AccountingCustomerParty/cbc:AdditionalAccountID[text()='6'] and not(regexp:match(cac:AccountingCustomerParty/cbc:CustomerAssignedAccountID,'^[0-9]{11}$|^[-]{1}$'))">
				<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2017'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2017)'" /> </xsl:call-template>
			</xsl:if>

			
		
		
		<!-- Valida que el tipo de documento del adquiriente exista y sea solo 
			uno -->
		<xsl:if test="count(cac:AccountingCustomerParty/cbc:AdditionalAccountID)>1">
			<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2363'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2363)'" /> </xsl:call-template>
		</xsl:if>

		<!-- Valida que el tipo de documento del adquiriente exista -->
		<xsl:if
			test="not(string(cac:AccountingCustomerParty/cbc:AdditionalAccountID))">
			<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2015'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2015)'" /> </xsl:call-template>
		</xsl:if>



		
		<!-- Si la operacion no es de exportacion el tipo de documento tiene que 
			ser 6, caso contrario puede ser 01467A o guion -->
		<xsl:choose>
			<xsl:when
				test='cac:DebitNoteLine/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cbc:TaxExemptionReasonCode[text()="40"] or substring(cbc:ID, 1, 1)="B" '>
				<xsl:if
					test='not(regexp:match(cac:AccountingCustomerParty/cbc:AdditionalAccountID,"^[01467A\-]{1}$"))'>
					<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2016'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2016)'" /> </xsl:call-template>
				</xsl:if>
			</xsl:when>
			<xsl:otherwise>
				<xsl:if
					test='substring(cbc:ID, 1, 1)="F" and not(cac:AccountingCustomerParty/cbc:AdditionalAccountID[text()=6 or text()=1])'>
					<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2016'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular NC (codigo: 2016)'" /> </xsl:call-template>
				</xsl:if>				
			</xsl:otherwise>
		</xsl:choose>


		<!-- JS 301116 Valida que el numero de documento del adquirente, si es DNI valida que conste de 8 caracteres numericos -->		
			<xsl:if test="not(cac:DebitNoteLine/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cbc:TaxExemptionReasonCode[text()='40']) or (not(substring(cbc:ID, 1, 1)='B'))">
				<xsl:if
					test="cac:AccountingCustomerParty/cbc:AdditionalAccountID[text()='1'] and not(regexp:match(cac:AccountingCustomerParty/cbc:CustomerAssignedAccountID,'^[0-9]{8}$'))">
					<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2801'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular NC (codigo: 2801)'" /> </xsl:call-template>
				</xsl:if>			
			</xsl:if>	

		
		

		<!-- Apellidos y nombres o denominacion o razon social del adquirente o 
			usuario -->
		<xsl:choose>
			<xsl:when
				test="not(string(cac:AccountingCustomerParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName))">
				<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2021'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2021)'" /> </xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:if
					test='not(regexp:match(cac:AccountingCustomerParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName,"^(?!\s*$).{1,100}"))'>
					<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2022'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2022)'" /> </xsl:call-template>
				</xsl:if>
			</xsl:otherwise>
		</xsl:choose>


		<!-- Detalle Nota de Debito -->
		<xsl:for-each select="cac:DebitNoteLine">
		
			<xsl:if test="count(key('by-invoiceLine-id', cbc:ID)) > 1">
                <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2752'" /> <xsl:with-param name="errorMessage" select="concat('El numero de item esta duplicado: ', cbc:ID)" /> </xsl:call-template>
            </xsl:if>

			<!-- Valor de venta por item -->
			<xsl:choose>
				<xsl:when test="not(./cbc:LineExtensionAmount)">
					<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2191'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2191)'" /> </xsl:call-template>
				</xsl:when>
				<xsl:otherwise>
					<xsl:if
						test='not(regexp:match(./cbc:LineExtensionAmount,"(-?[0-9]+){1,12}(\.[0-9]{1,2})?$"))'>
						<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2370'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2370)'" /> </xsl:call-template>
					</xsl:if>
				</xsl:otherwise>
			</xsl:choose>

			<!-- Numero de orden del item -->
			<xsl:if test='not(regexp:match(./cbc:ID,"^[0-9]{1,3}?$"))'>
				<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2187'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2187)'" /> </xsl:call-template>
			</xsl:if>

			<!-- Unidad de medida por item que modifica -->
			<xsl:if test='./cbc:DebitedQuantity/@unitCode'>
				<xsl:if
					test='not(regexp:match(./cbc:DebitedQuantity/@unitCode,"^[A-Z0-9]{1,3}?$"))'>
					<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2188'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2188)'" /> </xsl:call-template>
				</xsl:if>
			</xsl:if>

			<!-- Cantidad de unidades por item -->
			<xsl:if test='./cbc:DebitedQuantity'>
				<xsl:if
					test='not(regexp:match(./cbc:DebitedQuantity,"^[0-9]{1,12}(\.[0-9]{1,10})?$"))'><!--16/01/2015 se corrigio la cantidad de decimales, decia 3 -->
					<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2189'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2189)'" /> </xsl:call-template>
				</xsl:if>
			</xsl:if>

			<!-- Precio de venta unitario por item que modifica -->
			<xsl:if
				test="(count(./cac:PricingReference/cac:AlternativeConditionPrice/cbc:PriceTypeCode[text()='01'])>1 or count(./cac:PricingReference/cac:AlternativeConditionPrice/cbc:PriceTypeCode[text()='02'])>1)">
				<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2409'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND  (codigo: 2409)'" /> </xsl:call-template>
			</xsl:if>

			<!-- Precio de venta unitario por item que -->
			<xsl:if
				test='./cac:PricingReference/cac:AlternativeConditionPrice/cbc:PriceTypeCode'>
				<xsl:if
					test='not(./cac:PricingReference/cac:AlternativeConditionPrice/cbc:PriceTypeCode=01 or ./cac:PricingReference/cac:AlternativeConditionPrice/cbc:PriceTypeCode=02)'>
					<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2192'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2192)'" /> </xsl:call-template>
				</xsl:if>
			</xsl:if>


			<xsl:if
				test='./cac:PricingReference/cac:AlternativeConditionPrice/cbc:PriceAmount'>
				<xsl:choose>
					<xsl:when
						test='./cac:PricingReference/cac:AlternativeConditionPrice/cbc:PriceTypeCode=02 and not(regexp:match(./cac:PricingReference/cac:AlternativeConditionPrice/cbc:PriceAmount,"^[0-9]{1,12}(\.[0-9]{1,10})?$"))'>
						<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2408'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2408)'" /> </xsl:call-template>
					</xsl:when>
					<xsl:otherwise>
						<xsl:if
							test='./cac:PricingReference/cac:AlternativeConditionPrice/cbc:PriceTypeCode=01 and not(regexp:match(./cac:PricingReference/cac:AlternativeConditionPrice/cbc:PriceAmount,"^[0-9]{1,12}(\.[0-9]{1,10})?$"))'>
							<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2367'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2367)'" /> </xsl:call-template>
						</xsl:if>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:if>

			<!-- Valor unitario por item -->
			<xsl:choose>
				<xsl:when test='not(./cac:Price/cbc:PriceAmount)'>
					<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2190'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2190)'" /> </xsl:call-template>
				</xsl:when>
				<xsl:otherwise>
					<xsl:if
						test='not(regexp:match(./cac:Price/cbc:PriceAmount,"^[0-9]{1,12}(\.[0-9]{1,10})?$"))'>
						<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2369'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2369)'" /> </xsl:call-template>
					</xsl:if>
				</xsl:otherwise>
			</xsl:choose>

			<!-- Afectacion al IGV por item - Sistema de ISC por item -->
			<xsl:for-each select="./cac:TaxTotal">
				<xsl:if test='./cbc:TaxAmount'>
					<xsl:if
						test="./cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID=1000 and count(./cbc:TaxAmount)>1">
						<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2355'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2355)'" /> </xsl:call-template>
					</xsl:if>
					<xsl:if
						test="./cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID=2000 and count(./cbc:TaxAmount)>1">
						<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2356'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2356)'" /> </xsl:call-template>
					</xsl:if>
				</xsl:if>
				<!-- agregado 27/01/2014 inicio -->
				<xsl:if test="./cbc:TaxAmount!=./cac:TaxSubtotal/cbc:TaxAmount">
					<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2372'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2372)'" /> </xsl:call-template>
				</xsl:if>
				<!-- agregado 27/01/2014 fin -->

				<xsl:if test='./cac:TaxSubtotal/cbc:TaxAmount'>
					<xsl:if
						test='not(regexp:match(./cac:TaxSubtotal/cbc:TaxAmount,"^[0-9]{1,12}(\.[0-9]{1,2})?$"))'>
						<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2368'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2368)'" /> </xsl:call-template>
					</xsl:if>
				</xsl:if>

				<xsl:if
					test='./cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID=1000'>
					<xsl:choose>
						<xsl:when
							test="not(./cac:TaxSubtotal/cac:TaxCategory/cbc:TaxExemptionReasonCode)">
							<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2371'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2371)'" /> </xsl:call-template>
						</xsl:when>
						<xsl:otherwise>
							<xsl:if
								test="not(./cac:TaxSubtotal/cac:TaxCategory/cbc:TaxExemptionReasonCode[text()=10 or text()=11 or text()=12 or text()=13 or text()=14 or 
																		text()=15 or text()=16 or text()=20 or 
																		text()=30 or text()=31 or text()=32 or text()=33 or text()=34 or 
																		text()=35 or text()=36 or text()=40 or text()=21])">
								<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2197'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2197)'" /> </xsl:call-template>
							</xsl:if>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:if>
				<xsl:if
					test='./cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID=2000'>
					<xsl:choose>
						<xsl:when
							test="./cbc:TaxAmount>0 and not(string(./cac:TaxSubtotal/cac:TaxCategory/cbc:TierRange))">
							<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2373'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2373)'" /> </xsl:call-template>
						</xsl:when>
						<xsl:otherwise>
							<xsl:if
								test="not(./cac:TaxSubtotal/cac:TaxCategory/cbc:TierRange=01 or ./cac:TaxSubtotal/cac:TaxCategory/cbc:TierRange=02 or ./cac:TaxSubtotal/cac:TaxCategory/cbc:TierRange=03)">
								<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2199'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2199)'" /> </xsl:call-template>
							</xsl:if>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:if>

				<xsl:if test='./cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID'>
					<xsl:if
						test='not(regexp:match(./cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID,"^[0-9]{4}$"))'>
						<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2193'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2193)'" /> </xsl:call-template>
					</xsl:if>
					<xsl:if
						test="not(./cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID=1000 or ./cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID=2000)">
						<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2194'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2194)'" /> </xsl:call-template>
					</xsl:if>

					<xsl:choose>
						<xsl:when
							test="not(./cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:Name)">
							<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2195'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2195)'" /> </xsl:call-template>
						</xsl:when>
						<xsl:otherwise>
							<xsl:if
								test='not(regexp:match(./cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:Name,"^[A-Z]{1,6}?$"))'>
								<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2195'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2195)'" /> </xsl:call-template>
							</xsl:if>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:if>

				<xsl:if test='./cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID'>
					<xsl:if
						test='./cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID=1000'>
						<xsl:if
							test="not(./cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:Name='IGV') or not(./cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:TaxTypeCode='VAT')">
							<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2377'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2377)'" /> </xsl:call-template>
						</xsl:if>
					</xsl:if>
					<xsl:if
						test='./cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID=2000'>
						<xsl:if
							test="not(./cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:Name='ISC') or not(./cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:TaxTypeCode='EXC')">
							<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2378'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2378)'" /> </xsl:call-template>
						</xsl:if>
					</xsl:if>
				</xsl:if>

				<xsl:if
					test='./cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:TaxTypeCode'>
					<xsl:if
						test='not(regexp:match(./cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:TaxTypeCode,"^[A-Z]{3}$|^$"))'>
						<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2196'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2196)'" /> </xsl:call-template>
					</xsl:if>
				</xsl:if>
			</xsl:for-each>

		</xsl:for-each>


		<!-- Sumatoria IGV / ISC / Otros Tributos -->
		<xsl:for-each select="cac:TaxTotal">
			<xsl:choose>
				<xsl:when test="not(./cbc:TaxAmount)">
					<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2203'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2203)'" /> </xsl:call-template>
				</xsl:when>
				<xsl:otherwise>
					<xsl:if
						test='./cbc:TaxAmount and not(regexp:match(./cbc:TaxAmount,"^[0-9]{1,12}(\.[0-9]{1,2})?$"))'>
						<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2202'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2202)'" /> </xsl:call-template>
					</xsl:if>
				</xsl:otherwise>
			</xsl:choose>

			<xsl:if test='./cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID'>
				<xsl:if
					test='./cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID=1000'>
					<xsl:if test="count(./cbc:TaxAmount)>1">
						<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2352'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2352)'" /> </xsl:call-template>
					</xsl:if>
				</xsl:if>
				<xsl:if
					test='./cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID=2000'>
					<xsl:if test="count(./cbc:TaxAmount)>1">
						<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2353'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2353)'" /> </xsl:call-template>
					</xsl:if>
				</xsl:if>
				<xsl:if
					test='./cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID=9999'>
					<xsl:if test="count(./cbc:TaxAmount)>1">
						<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2354'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2354)'" /> </xsl:call-template>
					</xsl:if>
				</xsl:if>
			</xsl:if>

			<xsl:if test="./cac:TaxSubtotal/cbc:TaxAmount">
				<xsl:if test="./cbc:TaxAmount!=./cac:TaxSubtotal/cbc:TaxAmount">
					<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2061'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2061)'" /> </xsl:call-template>
				</xsl:if>
			</xsl:if>

			<xsl:choose>
				<xsl:when
					test="not(string(./cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID))">
					<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2184'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2184)'" /> </xsl:call-template>
				</xsl:when>
				<xsl:otherwise>
					<xsl:if
						test='not(regexp:match(./cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID,"^[0-9]{4}$"))'>
						<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2182'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2182)'" /> </xsl:call-template>
					</xsl:if>
				</xsl:otherwise>
			</xsl:choose>
			<xsl:if test="./cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID">
				<xsl:if
					test="not(./cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID=1000 or ./cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID=2000 or ./cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID=9999)">
					<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2183'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2183)'" /> </xsl:call-template>
				</xsl:if>
			</xsl:if>

			<xsl:choose>
				<xsl:when
					test="not(string(./cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:Name))">
					<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2186'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2186)'" /> </xsl:call-template>
				</xsl:when>
				<xsl:otherwise>
					<xsl:if
						test='not(regexp:match(./cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:Name,"^[A-Z]{1,6}?$"))'>
						<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2185'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2185)'" /> </xsl:call-template>
					</xsl:if>
				</xsl:otherwise>
			</xsl:choose>

			<xsl:if
				test="./cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID=1000 and not(./cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:Name='IGV')">
				<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2057'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2057)'" /> </xsl:call-template>
			</xsl:if>
			<xsl:if
				test="./cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID=2000 and not(./cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:Name='ISC')">
				<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2058'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2058)'" /> </xsl:call-template>
			</xsl:if>

			<xsl:if
				test="./cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:TaxTypeCode">
				<xsl:if
					test="./cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID=1000 and not(./cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:TaxTypeCode='VAT')">
					<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2057'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2057)'" /> </xsl:call-template>
				</xsl:if>
				<xsl:if
					test="./cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID=2000 and not(./cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:TaxTypeCode='EXC')">
					<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2058'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2058)'" /> </xsl:call-template>
				</xsl:if>
			</xsl:if>
		</xsl:for-each>

		<!-- Sumatoria otros Cargos -->
		<xsl:if test="cac:RequestedMonetaryTotal/cbc:ChargeTotalAmount">
			<xsl:if
				test='not(regexp:match(cac:RequestedMonetaryTotal/cbc:ChargeTotalAmount,"^[0-9]{1,12}(\.[0-9]{1,2})?$"))'>
				<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2064'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2064)'" /> </xsl:call-template>
			</xsl:if>
		</xsl:if>

		<!-- Total descuentos - Total valor de venta - operaciones gravadas - operaciones 
			inafectas - operaciones exoneradas -->
		<xsl:for-each
			select="ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/sac:AdditionalInformation/sac:AdditionalMonetaryTotal">
			<xsl:if test='./cbc:PayableAmount'>
				<xsl:if
					test='not(regexp:match(./cbc:PayableAmount,"^[0-9]{1,12}(\.[0-9]{1,2})?$"))'>
					<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2339'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2339)'" /> </xsl:call-template>
				</xsl:if>
			</xsl:if>

			<xsl:choose>
				<xsl:when test="not(string(./cbc:ID))">
					<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2341'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2341)'" /> </xsl:call-template>
				</xsl:when>
				<xsl:otherwise>
					<xsl:if test='not(regexp:match(./cbc:ID,"^[0-9]{4}$"))'>
						<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2340'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2340)'" /> </xsl:call-template>
					</xsl:if>
				</xsl:otherwise>
			</xsl:choose>
			<xsl:if test="(./cbc:ID=1001 and count(./cbc:ID)>1)">
				<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2349'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2349)'" /> </xsl:call-template>
			</xsl:if>
			<xsl:if test="(./cbc:ID=1002 and count(./cbc:ID)>1)">
				<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2350'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2350)'" /> </xsl:call-template>
			</xsl:if>
			<xsl:if test="(./cbc:ID=1003 and count(./cbc:ID)>1)">
				<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2351'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2351)'" /> </xsl:call-template>
			</xsl:if>
			<xsl:if
				test="(./cbc:ID=1001 and count(./cbc:ID)>1) or (./cbc:ID=1002 and count(./cbc:ID)>1) or (./cbc:ID=1003 and count(./cbc:ID)>1)">
				<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2046'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2046)'" /> </xsl:call-template>
			</xsl:if>
		</xsl:for-each>

		<!-- Importe total -->
		<xsl:if test="cac:RequestedMonetaryTotal/cbc:PayableAmount">
			<xsl:choose>
				<xsl:when
					test="not(string(cac:RequestedMonetaryTotal/cbc:PayableAmount))">
					<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2201'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2201)'" /> </xsl:call-template>
				</xsl:when>
				<xsl:otherwise>
					<xsl:if
						test='not(regexp:match(cac:RequestedMonetaryTotal/cbc:PayableAmount,"^[0-9]{1,12}(\.[0-9]{1,2})?$"))'>
						<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2062'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2062)'" /> </xsl:call-template>
					</xsl:if>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:if>

		<!-- Codigo del tipo de Nota de debito electronica -->
		<xsl:choose>
			<xsl:when test="not(string(cac:DiscrepancyResponse))">
				<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2414'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2414)'" /> </xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:if test='count(cac:DiscrepancyResponse)>1'>
					<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2415'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2415)'" /> </xsl:call-template>
				</xsl:if>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:choose>
			<xsl:when test="not(string(cac:DiscrepancyResponse/cbc:ResponseCode))">
				<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2173'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2173)'" /> </xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:if
					test='not(regexp:match(cac:DiscrepancyResponse/cbc:ResponseCode,"^[0-9]{2}$"))'>
					<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2172'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2172)'" /> </xsl:call-template>
				</xsl:if>
			</xsl:otherwise>
		</xsl:choose>

		<!-- Motivo o Sustento -->
		<xsl:choose>
			<xsl:when test="not(string(cac:DiscrepancyResponse/cbc:Description))">
				<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2136'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2136)'" /> </xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:if
					test='not(regexp:match(cac:DiscrepancyResponse/cbc:Description,"^(?!\s*$).{1,250}"))'>
					<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2135'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2135)'" /> </xsl:call-template>
				</xsl:if>
			</xsl:otherwise>
		</xsl:choose>


		<!-- Nota de debito para penalidades no importa si viene el documento que 
			modifica -->

		<xsl:if test="cac:DiscrepancyResponse/cbc:ResponseCode != '03'">

			<!-- tipo de nota F facturas y tickets B boletas -->

			<xsl:variable name="tipoDocumentoModifica" select="string(substring(cbc:ID, 1, 1))" />

			<xsl:for-each select="cac:BillingReference/cac:InvoiceDocumentReference">

				<xsl:if
					test="$tipoDocumentoModifica ='F' and not(./cbc:DocumentTypeCode[text() = '01' or text() = '12' or text() = '56'])">
					<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2204'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2204)'" /> </xsl:call-template>
				</xsl:if>

				<xsl:if
					test="$tipoDocumentoModifica ='B' and not(./cbc:DocumentTypeCode[text() = '03'])">
					<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2400'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2400)'" /> </xsl:call-template>
				</xsl:if>

				<xsl:if
					test="./cbc:DocumentTypeCode[text() = '01'] and not(regexp:match(./cbc:ID,'^[F][A-Z0-9]{3}-[0-9]{1,8}?$|^(E001)-[0-9]{1,8}?$|^[B][A-Z0-9]{3}-[0-9]{1,8}?$|^[0-9]{1,4}-[0-9]{1,8}?$') ) ">
					<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2205'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2205)'" /> </xsl:call-template>
				</xsl:if>


				<xsl:if
					test="./cbc:DocumentTypeCode[text() = '12'] and not(regexp:match(./cbc:ID,'^[a-zA-Z0-9-]{1,20}-[0-9]{1,10}?$') ) ">
					<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2205'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2205)'" /> </xsl:call-template>
				</xsl:if>


				<xsl:if
					test="./cbc:DocumentTypeCode[text() = '56'] and not(regexp:match(./cbc:ID,'^[\s]*$') ) ">
					<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2205'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2205)'" /> </xsl:call-template>
				</xsl:if>


				<xsl:if
					test="./cbc:DocumentTypeCode[text() = '03'] and not(regexp:match(./cbc:ID,'^[B][A-Z0-9]{3}-[0-9]{1,8}?$|^[0-9]{1,4}-[0-9]{1,8}?$') ) ">
					<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2205'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2205)'" /> </xsl:call-template>
				</xsl:if>

				<xsl:if test='count(./cbc:ID)=0'>
					<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2206'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2206)'" /> </xsl:call-template>
				</xsl:if>
			</xsl:for-each>



			<xsl:choose>
				<xsl:when test="not(string(cac:DiscrepancyResponse/cbc:ReferenceID))">
					<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2171'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2171)'" /> </xsl:call-template>
				</xsl:when>
				<xsl:otherwise>
					<xsl:if
						test='not(regexp:match(cac:DiscrepancyResponse/cbc:ReferenceID,"^[F][A-Z0-9]{3}-[0-9]{1,8}?$|^[B][A-Z0-9]{3}-[0-9]{1,8}?$|^[0-9]{1,4}-[0-9]{1,8}?$") )'>
						<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2170'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2170)'" /> </xsl:call-template>
					</xsl:if>
				</xsl:otherwise>
			</xsl:choose>

		</xsl:if>



		<!-- Documento de referencia -->
		<xsl:if test="cac:DespatchDocumentReference/cbc:DocumentTypeCode">
			<xsl:choose>
				<xsl:when
					test='not(regexp:match(cac:DespatchDocumentReference/cbc:DocumentTypeCode,"^[0-9]{2}$"))'>
					<xsl:call-template name="addWarning"> <xsl:with-param name="warningCode" select="'4004'"/> <xsl:with-param name="warningMessage" select="'warning 4004'"/></xsl:call-template>
				</xsl:when>
				<xsl:otherwise>
					<xsl:if
						test="not((cac:DespatchDocumentReference/cbc:DocumentTypeCode=09) or (cac:DespatchDocumentReference/cbc:DocumentTypeCode=31))">
						<xsl:call-template name="addWarning"> <xsl:with-param name="warningCode" select="'4005'"/> <xsl:with-param name="warningMessage" select="'warning 4005'"/></xsl:call-template>
					</xsl:if>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:if>

		<xsl:if test="cac:DespatchDocumentReference/cbc:ID">
			<xsl:choose>
				<xsl:when test='not(cac:DespatchDocumentReference/cbc:ID)'>
					<xsl:call-template name="addWarning"> <xsl:with-param name="warningCode" select="'4007'"/> <xsl:with-param name="warningMessage" select="'warning 4007'"/></xsl:call-template>
				</xsl:when>
				<xsl:otherwise>
					<xsl:if
						test='not(regexp:match(cac:DespatchDocumentReference/cbc:ID,"^(.){1,4}-[0-9]{1,}$"))'>
						<xsl:call-template name="addWarning"> <xsl:with-param name="warningCode" select="'4006'"/> <xsl:with-param name="warningMessage" select="'warning 4006'"/></xsl:call-template>
					</xsl:if>
				</xsl:otherwise>
			</xsl:choose>
			<!-- <xsl:if
				test="(cac:DespatchDocumentReference/cbc:DocumentTypeCode=09 or cac:DespatchDocumentReference/cbc:DocumentTypeCode=31) and (count(cac:DespatchDocumentReference/cbc:DocumentTypeCode)>1 or count(cac:DespatchDocumentReference/cbc:ID)>1)">
				<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2364'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2364)'" /> </xsl:call-template>
			</xsl:if> -->
		</xsl:if>

		<xsl:if test="cac:AdditionalDocumentReference/cbc:DocumentTypeCode">
			<xsl:choose>
				<xsl:when
					test='not(regexp:match(cac:AdditionalDocumentReference/cbc:DocumentTypeCode,"^[0-9]{2}$"))'>
					<xsl:call-template name="addWarning"> <xsl:with-param name="warningCode" select="'4008'"/> <xsl:with-param name="warningMessage" select="'warning 4008'"/></xsl:call-template>
				</xsl:when>
				<xsl:otherwise>
					<xsl:if
						test="not((cac:AdditionalDocumentReference/cbc:DocumentTypeCode=04) or (cac:AdditionalDocumentReference/cbc:DocumentTypeCode=05) or (cac:AdditionalDocumentReference/cbc:DocumentTypeCode=99) or (cac:AdditionalDocumentReference/cbc:DocumentTypeCode=01))">
						<xsl:call-template name="addWarning"> <xsl:with-param name="warningCode" select="'4009'"/> <xsl:with-param name="warningMessage" select="'warning 4009'"/></xsl:call-template>
					</xsl:if>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:if>

		<xsl:if test="cac:AdditionalDocumentReference/cbc:ID">
			<xsl:choose>
				<xsl:when test='not(cac:AdditionalDocumentReference/cbc:ID)'>
					<xsl:call-template name="addWarning"> <xsl:with-param name="warningCode" select="'4011'"/> <xsl:with-param name="warningMessage" select="'warning 4011'"/></xsl:call-template>
				</xsl:when>
				<xsl:otherwise>
					<xsl:if
						test='	not(regexp:match(cac:AdditionalDocumentReference/cbc:ID,"^^[0-9]{1,6}?$"))'>
						<xsl:call-template name="addWarning"> <xsl:with-param name="warningCode" select="'4010'"/> <xsl:with-param name="warningMessage" select="'warning 4010'"/></xsl:call-template>
					</xsl:if>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:if>
	<!-- Comentado y remplazado por key con conteo
	<xsl:if
			test="(cac:AdditionalDocumentReference/cbc:DocumentTypeCode=04 or cac:AdditionalDocumentReference/cbc:DocumentTypeCode=05 or cac:AdditionalDocumentReference/cbc:DocumentTypeCode=99 or cac:AdditionalDocumentReference/cbc:DocumentTypeCode=01) and (count(cac:AdditionalDocumentReference/cbc:DocumentTypeCode)>1 or count(cac:AdditionalDocumentReference/cbc:ID)>1)">
			<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2365'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2365)'" /> </xsl:call-template>
		</xsl:if> -->

		<!-- NUEVAS VALIDACIONES 27/01/2014 inicio -->
		<!-- Tipo de moneda en la cual se emite la NOTA DE DEBITO electronica -->
		<xsl:choose>
			<xsl:when test="not(string(cbc:DocumentCurrencyCode))">
				<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2070'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2070)'" /> </xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:if
					test='not(regexp:match(cbc:DocumentCurrencyCode,"^[A-Z0-9]{3}$"))'>
					<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2069'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2069)'" /> </xsl:call-template>
				</xsl:if>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:if
			test="(cbc:DocumentCurrencyCode!=cac:TaxTotal/cbc:TaxAmount/@currencyID) or (cbc:DocumentCurrencyCode!=cac:TaxTotal/cac:TaxSubtotal/cbc:TaxAmount/@currencyID) or (cbc:DocumentCurrencyCode!=cac:LegalMonetaryTotal/cbc:ChargeTotalAmount/@currencyID) or (cbc:DocumentCurrencyCode!=cac:DebitNoteLine/cac:PricingReference/cac:AlternativeConditionPrice/cbc:PriceAmount/@currencyID) or (cbc:DocumentCurrencyCode!=cac:DebitNoteLine/cac:Price/cbc:PriceAmount/@currencyID) or (cbc:DocumentCurrencyCode!=cac:DebitNoteLine/cbc:LineExtensionAmount/@currencyID) or (cbc:DocumentCurrencyCode!=cac:DebitNoteLine/cac:TaxTotal/cbc:TaxAmount/@currencyID) or (cbc:DocumentCurrencyCode!=cac:DebitNoteLine/cac:TaxTotal/cac:TaxSubtotal/cbc:TaxAmount/@currencyID)">
			<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2071'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2071)'" /> </xsl:call-template>
		</xsl:if>
		<xsl:if
			test="(cbc:DocumentCurrencyCode!=ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/sac:AdditionalInformation/sac:AdditionalMonetaryTotal/cbc:PayableAmount/@currencyID)">
			<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2071'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND (codigo: 2071)'" /> </xsl:call-template>
		</xsl:if>


		<!-- NUEVAS VALIDACIONES 27/01/2014 fin -->
		<!-- Documentos Relacionados Duplicados -->

		<xsl:for-each select="cac:BillingReference">
			<xsl:if
				test="count(key('by-document-billing-reference', concat(cac:InvoiceDocumentReference/cbc:DocumentTypeCode,' ', cac:InvoiceDocumentReference/cbc:ID))) > 1">
				<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2365'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND  (codigo: 2365)'" /> </xsl:call-template>
			</xsl:if>
		</xsl:for-each>

		<xsl:for-each select="cac:DespatchDocumentReference">
			<xsl:if
				test="count(key('by-document-despatch-reference', concat(cbc:DocumentTypeCode,' ', cbc:ID))) > 1">
				<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2364'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND  (codigo: 2364)'" /> </xsl:call-template>
			</xsl:if>
		</xsl:for-each>

		<xsl:for-each select="cac:AdditionalDocumentReference">
			<xsl:if
				test="count(key('by-document-additional-reference', concat(cbc:DocumentTypeCode,' ', cbc:ID))) > 1">
				<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2426'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular ND  (codigo: 2426)'" /> </xsl:call-template>
			</xsl:if>
		</xsl:for-each>

		<!-- Documentos Relacionados Duplicados fin -->
		<!-- </xsl:variable> <xsl:choose> <xsl:when test="string-length($errores)!=0"> 
			<xsl:value-of select="$errores"/> </xsl:when> <xsl:otherwise> -->
		<xsl:copy-of select="." />
		<!-- </xsl:otherwise> </xsl:choose> -->
	</xsl:template>
</xsl:stylesheet>
