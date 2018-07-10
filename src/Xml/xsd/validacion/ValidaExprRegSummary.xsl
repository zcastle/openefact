<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xs="http://www.w3.org/2001/XMLSchema" 
	xmlns:regexp="http://exslt.org/regular-expressions"
	xmlns:dyn="http://exslt.org/dynamic"
	xmlns:gemfunc="http://www.sunat.gob.pe/gem/functions"
	xmlns:date="http://exslt.org/dates-and-times"
	xmlns:func="http://exslt.org/functions"
	xmlns="urn:sunat:names:specification:ubl:peru:schema:xsd:Perception-1"
	xmlns:ds="http://www.w3.org/2000/09/xmldsig#"
	xmlns:ext="urn:oasis:names:specification:ubl:schema:xsd:CommonExtensionComponents-2"
	xmlns:sac="urn:sunat:names:specification:ubl:peru:schema:xsd:SunatAggregateComponents-1"
	xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2"
	xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2"
	xmlns:dp="http://www.datapower.com/extensions"
	extension-element-prefixes="dp" exclude-result-prefixes="dp dyn regexp date func" version="1.0">
	<!-- xsl:include href="../../../commons/error/error_utils.xsl" dp:ignore-multiple="yes" /-->
	<xsl:include href="local:///commons/error/error_utils.xsl" dp:ignore-multiple="yes" />
	<xsl:include href="local:///commons/error/validate_utils.xsl" dp:ignore-multiple="yes" />
	

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
        
        
	
		
		<!-- Variables -->
		<xsl:variable name="cbcUBLVersionID" select="cbc:UBLVersionID"/>

		<xsl:variable name="cbcCustomizationID"	select="cbc:CustomizationID"/>
		
		<xsl:variable name="cbcID" select="cbc:ID"/>
		
		<!--  fecha de generacion del resumen -->
		<xsl:variable name="cbcIssueDate" select="cbc:IssueDate"/>
		
		<!-- Fecha de los comprobantes de pago -->
		<xsl:variable name="cbcReferenceDate" select="cbc:ReferenceDate"/>
		

		<!-- Datos del Emisor Electrónico -->
		<xsl:variable name="emisor" select="cac:AccountingSupplierParty"/>
		
		<!-- Mandatorio -->
		<xsl:variable name="emisorTipoDocumento" select="$emisor/cbc:AdditionalAccountID"/>
		
		<!-- Mandatorio -->
		<xsl:variable name="emisorNumeroDocumento" select="$emisor/cbc:CustomerAssignedAccountID"/>
		
		<!-- Opcional -->
		<xsl:variable name="emisorRazonSocial" select="$emisor/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName"/>
		
		<!-- Fin Datos del Emisor Electrónico -->
		
		<!-- Fin Variables -->
		
		<!-- Validaciones -->
		
		<!-- Version del UBL -->
		<xsl:call-template name="existAndRegexpValidateElement">
			<xsl:with-param name="errorCodeNotExist" select="'2075'"/>
			<xsl:with-param name="errorCodeValidate" select="'2074'"/>
			<xsl:with-param name="node" select="$cbcUBLVersionID"/>
			<xsl:with-param name="regexp" select="'^(2.0)$'"/>
		</xsl:call-template>
		
		<!-- Version de la Estructura del Documento -->
		<xsl:call-template name="existAndRegexpValidateElement">
			<xsl:with-param name="errorCodeNotExist" select="'2073'"/>
			<xsl:with-param name="errorCodeValidate" select="'2072'"/>
			<xsl:with-param name="node" select="$cbcCustomizationID"/>
			<xsl:with-param name="regexp" select="'^(1.1)$'"/>
		</xsl:call-template>
		
		<!-- Numeracion, conformada por serie y numero correlativo -->
		<xsl:call-template name="existAndRegexpValidateElement">
			<xsl:with-param name="errorCodeNotExist" select="'2211'"/>
			<xsl:with-param name="errorCodeValidate" select="'2210'"/>
			<xsl:with-param name="node" select="$cbcID"/>
			<xsl:with-param name="regexp" select="'^[R][C]-[0-9]{8}-[0-9]{1,5}$'"/>
		</xsl:call-template>
		
		
		<!-- Fecha de emision, patron YYYY-MM-DD -->
		
		<!-- 8.- Fecha de emision del resumen de boleta --> <!-- <xsl:value-of select="./cbc:ReferenceDate"/> --> 
		
		<xsl:call-template name="existAndRegexpValidateElement">
			<xsl:with-param name="errorCodeNotExist" select="'2234'"/>
			<xsl:with-param name="errorCodeValidate" select="'2233'"/>
			<xsl:with-param name="node" select="$cbcReferenceDate"/>
			<xsl:with-param name="regexp" select="'^[0-9]{4}-[0-9]{2}-[0-9]{2}$'"/>
		</xsl:call-template>
		
	   
	    <xsl:variable name="fechaEmisionDDMMYYYY" select='concat(substring($cbcReferenceDate,9,2),"-",substring($cbcReferenceDate,6,2),"-",substring($cbcReferenceDate,1,4))'/>
	    
	    <xsl:if test='not(regexp:match($fechaEmisionDDMMYYYY,"^(?:(?:0?[1-9]|1\d|2[0-8])(\/|-)(?:0?[1-9]|1[0-2]))(\/|-)(?:[1-9]\d\d\d|\d[1-9]\d\d|\d\d[1-9]\d|\d\d\d[1-9])$|^(?:(?:31(\/|-)(?:0?[13578]|1[02]))|(?:(?:29|30)(\/|-)(?:0?[1,3-9]|1[0-2])))(\/|-)(?:[1-9]\d\d\d|\d[1-9]\d\d|\d\d[1-9]\d|\d\d\d[1-9])$|^(29(\/|-)0?2)(\/|-)(?:(?:0[48]00|[13579][26]00|[2468][048]00)|(?:\d\d)?(?:0[48]|[2468][048]|[13579][26]))$"))'>
	    	<xsl:call-template name="rejectCall">
				<xsl:with-param name="errorCode" select="'2235'" />
				<xsl:with-param name="errorMessage" select="concat('Fecha de emision de comprobantes (ReferenceDate): ', $cbcReferenceDate)" />				 
			</xsl:call-template>
	    </xsl:if>
    
	    <xsl:variable name="fechaRangos" select="$cbcReferenceDate"/>
	    <xsl:variable name="currentdate" select="date:date()"></xsl:variable>
	    <xsl:if test="((substring-before(date:difference($currentdate, concat($fechaRangos,'-00:00')),'D') != 'P0') and (substring-before(date:difference($currentdate, concat($fechaRangos,'-00:00')),'P')  != substring-before('-P','P')))">
			<xsl:call-template name="rejectCall">
				<xsl:with-param name="errorCode" select="'2237'" />
				<xsl:with-param name="errorMessage" select="concat('Fecha de proceso: hoy: ', $currentdate,' fecha de emision de comprobantes (ReferenceDate): ', $cbcReferenceDate)" />				 
			</xsl:call-template>
	    </xsl:if>
	    
	    <!-- 9.- Fecha de emision de de los comprobantes  --> 
    
    	<xsl:call-template name="existAndRegexpValidateElement">
			<xsl:with-param name="errorCodeNotExist" select="'2231'"/>
			<xsl:with-param name="errorCodeValidate" select="'2230'"/>
			<xsl:with-param name="node" select="$cbcIssueDate"/>
			<xsl:with-param name="regexp" select="'^[0-9]{4}-[0-9]{2}-[0-9]{2}$'"/>
		</xsl:call-template>
    

    
	    <xsl:variable name="fechaEmisionComDDMMYYYY" select='concat(substring(./cbc:IssueDate,9,2),"-",substring(./cbc:IssueDate,6,2),"-",substring(./cbc:IssueDate,1,4))'/>
	    
	    <xsl:if test='not(regexp:match($fechaEmisionComDDMMYYYY,"^(?:(?:0?[1-9]|1\d|2[0-8])(\/|-)(?:0?[1-9]|1[0-2]))(\/|-)(?:[1-9]\d\d\d|\d[1-9]\d\d|\d\d[1-9]\d|\d\d\d[1-9])$|^(?:(?:31(\/|-)(?:0?[13578]|1[02]))|(?:(?:29|30)(\/|-)(?:0?[1,3-9]|1[0-2])))(\/|-)(?:[1-9]\d\d\d|\d[1-9]\d\d|\d\d[1-9]\d|\d\d\d[1-9])$|^(29(\/|-)0?2)(\/|-)(?:(?:0[48]00|[13579][26]00|[2468][048]00)|(?:\d\d)?(?:0[48]|[2468][048]|[13579][26]))$"))'>
	    	<xsl:call-template name="rejectCall">
				<xsl:with-param name="errorCode" select="'2232'" />
				<xsl:with-param name="errorMessage" select="concat('Fecha de emision del resumen (cbcIssueDate): ', $cbcIssueDate)" />				 
			</xsl:call-template>
	    </xsl:if>
	    
	    <xsl:variable name="issuedate" select="./cbc:IssueDate"/>
	    <xsl:if test="(date:seconds(date:difference(concat($issuedate,'-00:00'),$currentdate)) &lt; 0)">
	    	
	    	<xsl:call-template name="rejectCall">
				<xsl:with-param name="errorCode" select="'2236'" />
				<xsl:with-param name="errorMessage" select="concat('Fecha de proceso: hoy: ', $currentdate,' fecha de emision del resumen: ', $issuedate)" />				 
			</xsl:call-template>
	    </xsl:if>
	    
	    <xsl:if test="(date:seconds(date:difference(concat($fechaRangos,'-00:00'),$issuedate)) &lt; 0)">
	    
	    	<xsl:call-template name="rejectCall">
				<xsl:with-param name="errorCode" select="'4036'" />
				<xsl:with-param name="errorMessage" select="concat('Fecha de regenracion del resumen: ', $issuedate, ' fecha de emision de comprobantes (ReferenceDate): ', $cbcReferenceDate)" />				 
			</xsl:call-template>
	
	    </xsl:if>
		
		<!-- Datos del Emisor Electrónico -->
		<!-- 6.- Tipo de Documento del Emisor - RUC --> <!-- <xsl:value-of select="./cac:AccountingSupplierParty/cbc:AdditionalAccountID"/> -->
		<!-- Tipo de documento de Identidad, por default 6-RUC - Mandatorio -->
		<xsl:call-template name="existAndRegexpValidateElement">
			<xsl:with-param name="errorCodeNotExist" select="'2219'"/>
			<xsl:with-param name="errorCodeValidate" select="'2218'"/>
			<xsl:with-param name="node" select="$emisorTipoDocumento"/>
			<xsl:with-param name="regexp" select="'^[6]{1}$'"/>
		</xsl:call-template>
		
				<!-- Numero de documento de identidad - Mandatorio -->
		<xsl:call-template name="existAndRegexpValidateElement">
			<xsl:with-param name="errorCodeNotExist" select="'2217'"/>
			<xsl:with-param name="errorCodeValidate" select="'2216'"/>
			<xsl:with-param name="node" select="$emisorNumeroDocumento"/>
			<xsl:with-param name="regexp" select="'^[0-9]{11}$'"/>
		</xsl:call-template>
		
		
    
    	<!-- 7.- Apellidos y nombres o denominacion o razon social Emisor --> <!-- <xsl:value-of select="./cac:AccountingSupplierParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName"/> -->
    	<xsl:call-template name="existAndRegexpValidateElement">
			<xsl:with-param name="errorCodeNotExist" select="'2229'"/>
			<xsl:with-param name="errorCodeValidate" select="'2228'"/>
			<xsl:with-param name="node" select="$emisorRazonSocial"/>
			<xsl:with-param name="regexp" select="'^[^\s].{1,100}'"/>
		</xsl:call-template>
    	
			
		<!-- Nombre comercial - Opcional -->
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'1038'"/>
			<xsl:with-param name="node" select="$cacAgentPartyNameName"/>
			<xsl:with-param name="regexp" select="'^(.{1,100})$'"/>
			<xsl:with-param name="descripcion" select="'El nombre comercial debe tener mas de un caracter'"/>
		</xsl:call-template>
		<!-- Fin Datos del Emisor Electrónico -->
		<!-- Validaciones de linea de resumen -->
		<xsl:apply-templates select="sac:SummaryDocumentsLine"/>
		
		<!-- Fin Validaciones -->
		
		<xsl:copy-of select="." />
		
	</xsl:template>
	
	
	<xsl:template match="sac:SummaryDocumentsLine">
		<!-- Tipo de comprobante	Tipo de comprobante a enviar en el resumen 
		.	Validar: El tipo de documento deberá de ser 03 (Boleta),12 (ticket), 07 (nota de crédito) o 08 (Nota de debito)	2511 "Tipo de documento inválido"
		-->
		<xsl:variable name="tipoComprobante" select="cbc:DocumentTypeCode"/>
		
		<!-- Total valor de venta-operaciones gravadas -->
		<xsl:variable name="totVentaOperGravadas" select="sac:BillingPayment[cbc:InstructionID='01']/cbc:PaidAmount"/>
		
		<!-- Total valor de venta-operaciones exoneradas -->
		<xsl:variable name="totVentaOperExoneradas" select="sac:BillingPayment[cbc:InstructionID='02']/cbc:PaidAmount"/>
		
		<!-- Total valor de venta - operaciones no gravadas -->
		<!-- Total valor de venta - operaciones inafectas -->
		<xsl:variable name="totVentaOperInafectas" select="sac:BillingPayment[cbc:InstructionID='03']/cbc:PaidAmount"/>
		
		<!-- Total valor de venta - operaciones gratuitas -->
		<xsl:variable name="totVentaOperGratuitas" select="sac:BillingPayment[cbc:InstructionID='05']/cbc:PaidAmount"/>
		
		<!-- Importe total de sumatoria otros cargos del item -->
		<xsl:variable name="totOtrosCargos" select="cac:AllowanceCharge/cbc:Amount"/>
		
		<!-- Total IGV -->
		
		<xsl:variable name="totIGV" select="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID='1000']/cbc:TaxAmount"/>
		 
		<!-- Total ISC --> 
		<xsl:variable name="totISC" select="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID='2000']/cbc:TaxAmount"/>
		<!-- Total otros tributos --> 
		<xsl:variable name="totOtrosTributos" select="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID='9999']/cbc:TaxAmount"/>
		
		<!-- Importe total de la venta, cesion en uso o del servicio prestado -->
		<xsl:variable name="totVentaOservicioPrestado" select="sac:TotalAmount"/>
		
		<!-- Moneda comprobante-->
		<xsl:variable name="monedaComprobante" select="sac:TotalAmount/@currencyID"/>
		
		
		<!-- Inicio de validaciones  -->
		
		<!-- Las monedas deben de ser iguales: -->
		<xsl:variable name="nodosConMonedaDiferente" select="./descendant::*[@currencyID != $monedaComprobante]"/>
		<xsl:if test="count($nodosConMonedaDiferente)>1">
			<xsl:variable name="nodoConError">
				<dp:serialize select="$nodosConMonedaDiferente[1]/parent::node()" omit-xml-decl="yes" />
			</xsl:variable>	
		
			<xsl:call-template name="rejectCall">
				<xsl:with-param name="errorCode" select="'2071'" />
				<xsl:with-param name="errorMessage" select="concat('Error en la linea', position(),'Las monedas son diferentes, linea : ',cbc:LineID,' (nodo: &quot;',$nodoConError, '&quot; moneda error: &quot;', $nodosConMonedaDiferente[1]/@currencyID, '&quot; Moneda comprobante: &quot;',monedaComprobante,'&quot;)')" />				 
			</xsl:call-template>
		</xsl:if> 
		
		<!-- El tipo de documento debera de ser 03 (Boleta), 12 (ticket),07 (nota de crédito) o 08  (Nota de debito) -->
		<xsl:call-template name="existAndRegexpValidateElement">
			<xsl:with-param name="errorCodeNotExist" select="'2516'"/>
			<xsl:with-param name="errorCodeValidate" select="'2511'"/>
			<xsl:with-param name="node" select="$tipoComprobante"/>
			<xsl:with-param name="regexp" select="'^(03|12|08|07)$'"/>
			<xsl:with-param name="descripcion" select="concat('El tipo de documento debera de ser 03 (Boleta), 12 (ticket),07 (nota de crédito) o 08  (Nota de debito).  Error en la linea', position())"/>
		</xsl:call-template>
			
			
		<!-- Numero de serie del comprobante y Numero correlativo del comprobante
		
		Validar: El campo debe de contener información
		Validar: El campo debe de iniciar con la Letra ‘B’ (Para 03,07 y 08)
		Validar: El campo debe de tener el siguiente formato: B###(donde # representa caracteres numéricos) (Para 03,07 y 08)
		Validar: El campo debe de ser numérico positivo y debe de tener como máximo 8 dígitos (Para 03,07 y 08)
		 -->
			 
		<xsl:choose>
			<xsl:when test="cbc:ID = '12'">
				<!-- 20 caracteres alfanumericos incluido el guion opcional el correlativo de 10 numeros -->
				<xsl:call-template name="regexpValidateElementIfExist">
				<xsl:with-param name="errorCodeValidate" select="'2513'"/>
				<xsl:with-param name="node" select="cbc:ID"/>
				<xsl:with-param name="regexp" select="'^[a-zA-Z0-9]{1,20}(-[0-9]{1,20})$'"/>
				<xsl:with-param name="descripcion" select="concat('Error en la linea', position())"/>
			</xsl:call-template>
			
			</xsl:when>
			<xsl:otherwise>
				<!-- Inicia con la letra B seguidos por tres caracteres alfanumericos seguidos por un guion
				     seguidos por 8 caracteres numericos pero todos los caracteres no deben ser 0  -->
				<xsl:call-template name="existAndRegexpValidateElement">
				<xsl:with-param name="errorCodeNotExist" select="'2512'"/>
				<xsl:with-param name="errorCodeValidate" select="'2513'"/>
				<xsl:with-param name="node" select="cbc:ID"/>
				<xsl:with-param name="regexp" select="'^([B][A-Z0-9]{3})-(?!0+$)([0-9]{1,8})$'"/>
				<xsl:with-param name="descripcion" select="concat('Error en la linea', position())"/>
			</xsl:call-template>	
			</xsl:otherwise>
		</xsl:choose>
			 
			 
			 
		<xsl:if test="$totVentaOservicioPrestado &gt; 750">
		
			<!-- Tipo de documento del adquiriente o usuario	SI importe total de venta > 750
			validar:
			El campo tipo de documento de identidad del adquiriente o usuario no debe estar vacio.	2514 "no existe información de receptor de documento".
		-->
			
			
		<xsl:call-template name="existAndRegexpValidateElement">
			<xsl:with-param name="errorCodeNotExist" select="'2514'"/>
			<xsl:with-param name="errorCodeValidate" select="'2015'"/>
			<xsl:with-param name="node" select="cac:AccountingCustomerParty/cbc:AdditionalAccountID"/>
			<xsl:with-param name="regexp" select="'^(0|1|4|6|7|A|-)$'"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea', position(), ': Si el importe total es mayor 750 se debe consignar tipo de documento de identidad del comprador')"/>
		</xsl:call-template>
		
		<!-- SI importe total de venta > 750 validar:
		El campo Número de documento de Identidad del adquirente o usuario no debe de estar vacio	
		2514 "no existe información de receptor de documento".
		 -->
		 
		 <xsl:call-template name="existAndRegexpValidateElement">
			<xsl:with-param name="errorCodeNotExist" select="'2514'"/>
			<xsl:with-param name="errorCodeValidate" select="'2018'"/>
			<xsl:with-param name="node" select="cac:AccountingCustomerParty/cbc:CustomerAssignedAccountID"/>
			<xsl:with-param name="regexp" select="'^([A-Z0-9_-]{4,20})$'"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea', position(), ': Si el importe total es mayor 750 se debe consignar numero de identidad del comprador')"/>
		</xsl:call-template>
		
		</xsl:if>
			 
		
		
		<!-- Total valor de venta - operaciones gravadas	
		Solo de corresponder. Total de valor de venta de las operaciones gravadas con IGV. 
		Monto que incluye la deducción de descuentos, si los hubiere.             	
		SI el campo Total valor de venta - operaciones gravadas  no está vacío validar:
		El campo debe de ser numérico,
		EL campo debe de ser mayor a cero
		El campo no debe de tener más de dos decimales.
		 -->
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'2517'"/>
			<xsl:with-param name="node" select="$totVentaOperGravadas"/>
			<xsl:with-param name="regexp" select="'(?!(^0+(\.0+)?$))(^\d{1,20}(\.\d{1,2})?$)'"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea', position(), ': El monto debe de ser un numero valido, como maximo dos decimales; mayor que cero')"/>
		</xsl:call-template>
		
		<!-- Total valor de venta - operaciones exoneradas	
			Total de valor de venta de las operaciones exoneradas con IGV. 
			Monto que incluye la deducción de descuentos, 
			si los hubiere.                                                                                                            	SI el campo Total valor de venta - operaciones exoneradas  no está vacío validar:
			El campo debe de ser numérico
			EL campo debe de ser mayor a cero
			El campo no debe de tener más de dos decimales.
		 -->
		 
		 <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'2517'"/>
			<xsl:with-param name="node" select="$totVentaOperExoneradas"/>
			<xsl:with-param name="regexp" select="'(?!(^0+(\.0+)?$))(^\d{1,20}(\.\d{1,2})?$)'"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea', position(), ': El monto debe de ser un numero valido, como maximo dos decimales; mayor que cero')"/>
		</xsl:call-template>
		
		
		<!-- Total valor de venta - operaciones inafectas 	
			Total de valor de venta de las operaciones exoneradas con IGV. Monto que incluye la deducción de descuentos, 
			si los hubiere.	SI el campo Total valor de venta - operaciones inafectas no está vacío validar:
			El campo debe de ser numérico
			EL campo debe de ser mayor a cero
			El campo no debe de tener más de dos decimales.
		 -->
		 
		 <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'2517'"/>
			<xsl:with-param name="node" select="$totVentaOperInafectas"/>
			<xsl:with-param name="regexp" select="'(?!(^0+(\.0+)?$))(^\d{1,20}(\.\d{1,2})?$)'"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea', position(), ': El monto debe de ser un numero valido, como maximo dos decimales; mayor que cero')"/>
		</xsl:call-template>
		
		
		<!--
		Total valor de venta - operaciones gratuitas	
		De no corresponder dejar vacío el campo	
		SI el campo Total valor de venta - operaciones gratuitas no está vacío validar:
		El campo debe de ser numérico. 
		 -->
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'2517'"/>
			<xsl:with-param name="node" select="$totVentaOperGratuitas"/>
			<xsl:with-param name="regexp" select="'^\d{1,20}(\.\d{1,10})?$'"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea', position(), ': El monto debe de ser un numero valido, como maximo 10 decimales')"/>
		</xsl:call-template>
		
		
		<!-- Importe total de Total otros cargos del ítem	Importe cero ("0.00") de no corresponder. 	
			SI el Importe total de Total otros cargos del ítem no está vacío
			Validar:
			El campo debe de ser numérico
			EL campo debe de ser mayor igual a cero
			El campo no debe de tener más de dos decimales.
		 -->
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'2517'"/>
			<xsl:with-param name="node" select="$totOtrosCargos"/>
			<xsl:with-param name="regexp" select="'^\d{1,20}(\.\d{1,2})?$'"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea', position(), ': El monto debe de ser un numero valido, como maximo 2 decimales')"/>
		</xsl:call-template>
		
		
		
		<!-- Total ISC	Impuesto selectivo al consumo.
			De no corresponder, dejar vacío el campo. 	SI el campo Total ISC no está vacío validar:
			El campo debe de ser numérico
			
			-->
			
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'2517'"/>
			<xsl:with-param name="node" select="$totISC"/>
			<xsl:with-param name="regexp" select="'^\d{1,20}(\.\d{1,10})?$'"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea', position(), ': El monto debe de ser un numero valido, como maximo 10 decimales')"/>
		</xsl:call-template>
			
		
		<!-- 
			Total IGV	Impuesto general a las ventas.
			De no corresponder, dejar vacío el campo. 	SI el campo Total IGV no está vacío validar:
			El campo debe de ser numérico
		
		 -->
		 
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'2517'"/>
			<xsl:with-param name="node" select="$totIGV"/>
			<xsl:with-param name="regexp" select="'^\d{1,20}(\.\d{1,10})?$'"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea', position(), ': El monto debe de ser un numero valido, como maximo 10 decimales')"/>
		</xsl:call-template>
		
		
		 
		
		<!-- Total Otros tributos 	
		De no corresponder dejar vacío el campo	SI el campo Total Otros tributos no está vacío validar:
		El campo debe de ser numérico
		EL campo debe de ser mayor a cero
		El campo no debe de tener más de dos decimales.
		 --> 
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'2517'"/>
			<xsl:with-param name="node" select="$totOtrosTributos"/>
			<xsl:with-param name="regexp" select="'(?!(^0+(\.0+)?$))(^\d{1,20}(\.\d{1,2})?$)'"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea', position(), ': El monto debe de ser un numero valido, como maximo dos decimales; mayor que cero')"/>
		</xsl:call-template>
		
		<!-- 13	Importe total de la venta, cesión en uso o del servicio prestado	
		De no corresponder dejar vacío el campo ( en qué caso no corresponde)	
		SI el campo Importe total de la venta, cesión en uso o del servicio prestado no está vacío validar:
			El campo debe de ser numérico
			EL campo debe de ser mayor a cero
			El campo no debe de tener más de dos decimales.	2517 “dato no cumple con el formato establecido”.

		sac:SummaryDocumentsLine/sac:TotalAmount
		 -->
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'2517'"/>
			<xsl:with-param name="node" select="$totVentaOservicioPrestado"/>
			<xsl:with-param name="regexp" select="'(?!(^0+(\.0+)?$))(^\d{1,20}(\.\d{1,2})?$)'"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea', position(), ': El monto debe de ser un numero valido, como maximo dos decimales; mayor que cero')"/>
		</xsl:call-template>
		
		
		
		<!-- 
		
			SI el campo Importe total de la venta, cessión en uso o del servicio prestado no está vacío validar:
			
			Total valor de venta-operaciones gravadas + Total valor de venta-operaciones no gravadas + Total valor de venta-operaciones exoneradas + 
			Total IGV + Total ISC + Total otros tributos + Total otros Cargos” - 5 menor igual " Importe total de la venta, cesión en uso o del servicio prestado".
			Y
			"Total valor de venta-operaciones gravadas + Total valor de venta-operaciones no gravadas + 
			Total valor de venta-operaciones exoneradas + Total IGV + Total ISC + Total otros tributos + Total otros Cargos”  + 5 mayor igual " 
			Importe total de la venta, cesión en uso o del servicio prestado".
		 -->
		<xsl:if test="$totVentaOservicioPrestado">
			<xsl:variable name="sumaCargosTributos" select="number($totOtrosTributos) + number($totIGV) + number($totISC) + number($totOtrosCargos) + number($totVentaOperInafectas) + number($totVentaOperExoneradas) + number($totVentaOperGravadas)"/>
			
			<xsl:if test="$totVentaOservicioPrestado + 5 &lt; $sumaCargosTributos and $totVentaOservicioPrestado - 5 &gt; $sumaCargosTributos">	
				<xsl:call-template name="addWarning">
					<xsl:with-param name="warningCode" select="'4027'" />
					<xsl:with-param name="warningMessage" select="concat('La suma de totales e impuestos no coincide: ',$totVentaOservicioPrestado, 'diferente de la venta total: ', $totVentaOservicioPrestado)" />
				</xsl:call-template>
			</xsl:if>
		</xsl:if>
		
		
		
		<xsl:choose>
			<xsl:when test="$tipoComprobante = '08' or $tipoComprobante = '07'">
				<xsl:apply-templates select="cac:BillingReference">
					<xsl:with-param name="tipoComprobante" select="$tipoComprobante"/>
				</xsl:apply-templates>
			</xsl:when>
			<xsl:otherwise>
				<!-- Si no son notas de credito o notas de debito no se deben enviar los tag de 
				documentos relacionados -->
				<xsl:if test="not(gemfunc:is-blank(cac:BillingReference))">
				
					<xsl:call-template name="rejectCall">
						<xsl:with-param name="errorCode" select="'2524'" />
						<xsl:with-param name="errorMessage" select="concat('Error en la linea', position(),'El tipo de comprobante es: ', $tipoComprobante,' Por lo cual no se debe de enviar el elemento cac:BillingReference')" />				 
					</xsl:call-template>
				</xsl:if>
				
			</xsl:otherwise>
		</xsl:choose>
		
		
		<!-- Tipo de operación a realizar para el comprobante enviado: 
			1: Adicionar
			2: Modificar
			3: anular	(en un día distinto al envio original)
			4: anular	(el mismo día distinto al envio original)
			Validar: que el campo exista y tenga el valor 1,2,3,4
		 -->
		 
		 <xsl:call-template name="existAndRegexpValidateElement">
			<xsl:with-param name="errorCodeNotExist" select="'2522'"/>
			<xsl:with-param name="errorCodeValidate" select="'2522'"/>
			<xsl:with-param name="node" select="cac:Status/cbc:ConditionCode"/>
			<xsl:with-param name="regexp" select="'^(1|2|3|4)$'"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea', position(), ': El tipo de operacion debe de ser 1, 2, 3 o 4')"/>
			
		</xsl:call-template>
		
		<!-- Valida percepcion  si es diferente de boleta o es diferente de alta y tiene percepcion error solo se acepta info
		     de percepcion para altas de boleta -->
		<xsl:if test="sac:SUNATPerceptionSummaryDocumentReference and ($tipoComprobante!='03' or cac:Status/cbc:ConditionCode!='1')">
			<xsl:call-template name="rejectCall">
				<xsl:with-param name="errorCode" select="'2517'" />
				<xsl:with-param name="errorMessage" select="concat('Error en la linea', position(), 'Solo se acepta infromacion de percepcion para nuevas boletas: el tipo de comprobante es: ', $tipoComprobante,' y debe de ser 03.')" />				 
			</xsl:call-template>
		</xsl:if>
		
		
		<xsl:if test="sac:SUNATPerceptionSummaryDocumentReference">
			<xsl:apply-templates select="sac:SUNATPerceptionSummaryDocumentReference">
				<xsl:with-param name="parent_position" select="position()"/>
			</xsl:apply-templates>
		</xsl:if>
		
	</xsl:template>
	
	
	<!-- Si el comprbante es una nota de credito debe de hacer referencia a una boleta de venta -->
	<xsl:template match="cac:BillingReference">
		<xsl:param name="tipoComprobante"/>
		
		<xsl:variable name="tipoComprobanteReferencia" select="cac:InvoiceDocumentReference/cbc:DocumentTypeCode"/>
		<xsl:variable name="serieNumeroComprobanteReferencia" select="cac:InvoiceDocumentReference/cbc:ID"/>

		<!-- Si el comprobante es una nota de crédito o nota de debito 
		el campo no debe de estar vacio	
		SI tipo de comprobante es  07 ó 08 validar:
		Tipo de comprobante que modifica = 03 ó 12 -->
		<xsl:call-template name="existAndRegexpValidateElement">
			<xsl:with-param name="errorCodeNotExist" select="'2512'"/>
			<xsl:with-param name="errorCodeValidate" select="'2513'"/>
			<xsl:with-param name="node" select="$tipoComprobanteReferencia"/>
			<xsl:with-param name="regexp" select="'^(12|03)$'"/>
			<xsl:with-param name="descripcion" select="'El tipo de comprobante relacionado debe de ser 12 (ticket) o 03 (boleta)'"/>
		</xsl:call-template>
		
		
		<!-- Si el comprobante es una nota de crédito o nota de debito el campo no debe de estar vacio	
		SI tipo de comprobante es  07 ó 08 validar:
			Número de serie de la boleta de venta que modifica no debe ser vacio
		 -->
		<xsl:if test="gemfunc:is-blank($serieNumeroComprobanteReferencia)">
			<xsl:call-template name="rejectCall">
				<xsl:with-param name="errorCode" select="'2512'" />
				<xsl:with-param name="errorMessage" select="concat('El tipo de comprobantes es: ', $tipoComprobante,' Por lo cual se debe de enviar el elemento cac:InvoiceDocumentReference/cbc:ID')" />				 
			</xsl:call-template>
		</xsl:if>
		
		<!-- 
			Número de serie de la boleta de venta que modifica + Tipo de comprobante que modifica	
			Si el tipo de documento a modificar es boleta debe de tener el formato de boleta	
			SI Tipo de comprobante que modifica = 03 validar:
			El campo debe de tener el siguiente formato: B###(donde # representa caracteres numéricos)
			seguido por un guion y segui por un numero como máximo de 8 dígitos
		 -->
		<xsl:variable name="comprobanteModificaID" select="cac:InvoiceDocumentReference/cbc:ID"/>
		<xsl:choose>
		 	<xsl:when test="$comprobanteModificaID = '12'">
				<!-- 20 caracteres alfanumericos incluido el guion opcional el correlativo de 10 numeros -->
			<xsl:call-template name="regexpValidateElementIfExist">
				<xsl:with-param name="errorCodeValidate" select="'2513'"/>
				<xsl:with-param name="node" select="$comprobanteModificaID"/>
				<xsl:with-param name="regexp" select="'(?!0+-)^[a-zA-Z0-9]{1,20}-(?!0+$)([0-9]{1,20})$'"/>
				<xsl:with-param name="descripcion" select="concat('Error en la linea', position())"/>
			</xsl:call-template>
			
			</xsl:when>
			<xsl:otherwise>
				<!-- Inicia con la letra B seguidos por tres caracteres alfanumericos seguidos por un guion
				     seguidos por 8 caracteres numericos pero todos los caracteres no deben ser 0  -->
				<xsl:call-template name="existAndRegexpValidateElement">
				<xsl:with-param name="errorCodeNotExist" select="'2512'"/>
				<xsl:with-param name="errorCodeValidate" select="'2513'"/>
				<xsl:with-param name="node" select="$comprobanteModificaID"/>
				<xsl:with-param name="regexp" select="'^([B][A-Z0-9]{3})-(?!0+$)([0-9]{1,8})$'"/>
				<xsl:with-param name="descripcion" select="concat('Error en la linea', position())"/>
			</xsl:call-template>	
			</xsl:otherwise>
		</xsl:choose>
		
	</xsl:template>
	
	
	
	
	<xsl:template match="sac:SUNATPerceptionSummaryDocumentReference">
		<xsl:param name="parent_position"/>

	<!-- catalogo 22 
		01	PERCEPCION VENTA INTERNA	TASA 2%
		02	PERCEPCION A LA ADQUISICION DE COMBUSTIBLE	TASA 1%
		03	PERCEPCION REALIZADA AL AGENTE DE PERCEPCION CON TASA ESPECIAL	TASA 0.5%
	 -->	
	 <!-- Regimen de percepcion debe de pertenecer al catalogo 22-->
	 <xsl:call-template name="findElementInCatalog">
	 	<xsl:with-param name="catalogo" select="'22'"/>
	 	<xsl:with-param name="idCatalogo" select="sac:SUNATPerceptionSystemCode"/>
	 	<xsl:with-param name="errorCodeValidate" select="'2517'"/>
	 </xsl:call-template>
	 
	 <!-- Tasa de percepción debe de pertenecer al catalogo 22-->
	 <xsl:call-template name="findElementInCatalogProperty">
	 	<xsl:with-param name="catalogo" select="'22'"/>
	 	<xsl:with-param name="propiedad" select="'tasa'"/>
	 	<xsl:with-param name="idCatalogo" select="sac:SUNATPerceptionSystemCode"/>
	 	<xsl:with-param name="valorPropiedad" select="number(sac:SUNATPerceptionPercent)"/>
	 	<xsl:with-param name="errorCodeValidate" select="'2517'"/>
	 </xsl:call-template>
	 
	 
	<!-- Monto total de la percepción tiene que ser mayor que cero-->
	 <xsl:call-template name="regexpValidateElementIfExist">
		<xsl:with-param name="errorCodeValidate" select="'2517'"/>
		<xsl:with-param name="node" select="cbc:TotalInvoiceAmount"/>
		<xsl:with-param name="regexp" select="'(?!(^0+(\.0+)?$))(^\d{1,20}(\.\d{1,2})?$)'"/>
		<xsl:with-param name="descripcion" select="concat('Error en la linea', $parent_position,'Monto total de la percepción debe de ser un numero valido, como maximo dos decimales; mayor que cero')"/>
	</xsl:call-template>
	
	
	<!-- Monto total a cobrar incluida la percepción  tiene que ser mayor que cero -->
	<xsl:call-template name="regexpValidateElementIfExist">
		<xsl:with-param name="errorCodeValidate" select="'2517'"/>
		<xsl:with-param name="node" select="sac:SUNATTotalCashed"/>
		<xsl:with-param name="regexp" select="'(?!(^0+(\.0+)?$))(^\d{1,20}(\.\d{1,2})?$)'"/>
		<xsl:with-param name="descripcion" select="concat('Error en la linea', $parent_position,'Monto total de la percepción debe de ser un numero valido, como maximo dos decimales; mayor que cero')"/>
	</xsl:call-template>
	
	<!-- Base imponible percepción -->
	<xsl:call-template name="regexpValidateElementIfExist">
		<xsl:with-param name="errorCodeValidate" select="'2517'"/>
		<xsl:with-param name="node" select="cbc:TaxableAmount"/>
		<xsl:with-param name="regexp" select="'(?!(^0+(\.0+)?$))(^\d{1,20}(\.\d{1,2})?$)'"/>
		<xsl:with-param name="descripcion" select="concat('Error en la linea', $parent_position,'Monto total de la percepción debe de ser un numero valido, como maximo dos decimales; mayor que cero')"/>
	</xsl:call-template>
	
	<xsl:variable name="sumaTotalCobrarMasPercepcion" select="number(cbc:TaxableAmount) + number(cbc:TotalInvoiceAmount)"/>
	 		
	<xsl:if test="number(number(sac:SUNATTotalCashed) + 1) &lt; number($sumaTotalCobrarMasPercepcion) or number(number(sac:SUNATTotalCashed) - 1) &gt; number($sumaTotalCobrarMasPercepcion)">
		<xsl:call-template name="rejectCall">
			<xsl:with-param name="errorCode" select="'4027'" />
			<xsl:with-param name="errorMessage" select="concat('Error en la linea', $parent_position,'Monto total a cobrar incluida la percepción no coincide: ',sac:SUNATTotalCashed, ' es diferente a la suma del Monto total de la percepción y la Base imponible percepción: ', $sumaTotalCobrarMasPercepcion)" />
		</xsl:call-template>
	</xsl:if>
		
	</xsl:template>
	
</xsl:stylesheet>
