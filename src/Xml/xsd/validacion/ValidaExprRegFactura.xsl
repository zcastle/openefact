<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:regexp="http://exslt.org/regular-expressions"
	xmlns:gemfunc="http://www.sunat.gob.pe/gem/functions"
	xmlns:func="http://exslt.org/functions"
	xmlns="urn:oasis:names:specification:ubl:schema:xsd:Invoice-2"
	xmlns:ds="http://www.w3.org/2000/09/xmldsig#"
	xmlns:ext="urn:oasis:names:specification:ubl:schema:xsd:CommonExtensionComponents-2"
	xmlns:sac="urn:sunat:names:specification:ubl:peru:schema:xsd:SunatAggregateComponents-1"
	xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2"
	xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2"
	xmlns:dp="http://www.datapower.com/extensions"
	extension-element-prefixes="dp" exclude-result-prefixes="dp" version="1.0">

    <!--xsl:include href="../../../commons/error/error_utils.xsl" dp:ignore-multiple="yes" / -->
	 <xsl:include href="error_utils.xsl" dp:ignore-multiple="yes" /> 

	<!-- Se aniade nuevo Template JS 091216-->
	<!-- <xsl:include href="local:///commons/checksum.xsl" dp:ignore-multiple="yes" /> -->


    <!-- key Documentos Relacionados Duplicados -->
    <xsl:key name="by-document-despatch-reference" match="*[local-name()='Invoice']/cac:DespatchDocumentReference" use="concat(cbc:DocumentTypeCode,' ', cbc:ID)"/>

    <xsl:key name="by-document-additional-reference" match="*[local-name()='Invoice']/cac:AdditionalDocumentReference" use="concat(cbc:DocumentTypeCode,' ', cbc:ID)"/>

    <!-- key Documentos Relacionados Duplicados fin -->
    <xsl:key name="by-pricingReference-alternativeConditionPrice-priceTypeCode" match="./cac:PricingReference/cac:AlternativeConditionPrice" use="cbc:PriceTypeCode"/>

    <!-- key Numero de lineas duplicados fin -->
    <xsl:key name="by-invoiceLine-id" match="*[local-name()='Invoice']/cac:InvoiceLine" use="number(cbc:ID)"/>

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

        <!-- Total valor de venta operaciones gravadas operaciones inafectas operaciones
			exoneradas Operaciones gratuitas Importe de la percepcion en moneda nacional -->

        <xsl:variable name="sacAdditionalInformation" select="ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/sac:AdditionalInformation"/>
        <xsl:variable name="additionalMonetaryTotal" select="$sacAdditionalInformation/sac:AdditionalMonetaryTotal"/>
        <xsl:variable name="additionalMonetaryTotalID" select="$additionalMonetaryTotal/cbc:ID"/>
        <!-- Tipo de transaccion -->
        <xsl:variable name="sacSUNATTransactionID" select="$sacAdditionalInformation/sac:SUNATTransaction/cbc:ID"/>

        <!-- Valida que solo exista un tag  sacAdditionalInformation-->
        <xsl:if test="count($sacAdditionalInformation)>1">
            <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2427'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2427)'" /> </xsl:call-template>
        </xsl:if>

		<!-- js_140615 _ RF07 traslado de bienes, validacion exclusiva de tags para sacSUNATTransactionID = 06 Inicio -->
        <!-- js_080715	b)Cuando el XML de factura, el tag “/sac:SUNATTransaction/cbc:ID” es diferente a  06 (Factura guía), debe validar lo siguiente:
				b.1  De existir el tag “sac:SUNATEmbededDespatchAdvice”, generar el código de WARNING TEMPORAL EN LUGAR DE ERROR 4047 – sac:SUNATTransaction/cbc:ID debe ser igual a 06 cuando ingrese información para sustentar el traslado.-->
        <xsl:if test="$sacSUNATTransactionID[text() != '06']">
            <xsl:if test="$sacAdditionalInformation/sac:SUNATEmbededDespatchAdvice">
                <xsl:call-template name="addWarning"> <xsl:with-param name="warningCode" select="'4047'"/> <xsl:with-param name="warningMessage" select="' Esta ingresando informacion de traslado de bienes en una transaccion que no es factura guia'"/></xsl:call-template>
            </xsl:if>
        </xsl:if>
        <!-- js_140615 Fin -->


        <xsl:if test="$sacSUNATTransactionID">

            <!--JS 100715 se agrega SUNATTransaction tipo 06 -->
            <!-- De existir el elemento, validar que el campo ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/sac:AdditionalInformation/sac:SUNATTransaction/cbc:ID
				tenga un valor del catalogo No 17 (01, 02, 03, 04, 05 o  06). Si no cumple, marcar
				OBS-4042. -->
			<!-- JS 201216-->
            <xsl:if test="not($sacSUNATTransactionID[text() = '01' or text() = '02' or text() = '03' or text() = '04' or text() = '05' or text() = '06' or text() = '07' or text() = '08' or text() = '09' or text() = '10' or text() = '11' or text() = '12'  or text() = '13'])">
                <xsl:call-template name="addWarning"> <xsl:with-param name="warningCode" select="'4042'"/> <xsl:with-param name="warningMessage" select="concat('el valor: ', $sacSUNATTransactionID, ' no se encuentra en el catalogo 17')"/></xsl:call-template>
            </xsl:if>
            <!-- JS 100715 -->


            <!-- Validaciones a  nivel global -->
            <!-- ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/sac:AdditionalInformation/sac:AdditionalMonetaryTotal/cbc:ID-->
            <!-- De ser tipo 04 (anticipos), se debe validar que: Existan los tags: /Invoice/cac:InvoiceLine/cac:Item/cbc:Description
				y /Invoice/cac:InvoiceLine/cbc:LineExtensionAmount. Si no cumple, marcar como ERROR-2500 -->
            <xsl:if test="$sacSUNATTransactionID[text() = '04'] and not(cac:InvoiceLine/cac:Item/cbc:Description and cac:InvoiceLine/cbc:LineExtensionAmount)">
                <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2500'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2500)'" /> </xsl:call-template>
            </xsl:if>

            <!-- De ser tipo 04 (anticipos), se debe validar que: El tag /Invoice/cac:InvoiceLine/cbc:LineExtensionAmount
				debe ser mayor que 0. Si no cumple, marcar ERRO -2501 -->
			<xsl:if test="$sacSUNATTransactionID[text() = '04'] and (cac:InvoiceLine/cbc:LineExtensionAmount[text()&lt;=0])">
                <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2501'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2501)'" /> </xsl:call-template>
            </xsl:if>


            <!-- De ser tipo 04 (anticipos) y ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/sac:AdditionalInformation/sac:AdditionalMonetaryTotal/cbc:ID
				es 1001 se debe validar que: El Total IGV (cac:TaxTotal/cbc:TaxAmount), y
				el Total de la operacion (/Invoice/cac:LegalMonetaryTotal/cbc:PayableAmount).
				Deben ser mayor a cero. Si no cumple. Marcar como ERROR-2502 -->
            <!-- Tambien se incluyo el error 2502 en un for-each -->
            <xsl:if test="$sacSUNATTransactionID[text() = '04'] and $additionalMonetaryTotalID[text()='1001'] and (cac:TaxTotal/cbc:TaxAmount[text() &lt;=0] or cac:LegalMonetaryTotal/cbc:PayableAmount[text() &lt;=0])">
                <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2502'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2502)'" /> </xsl:call-template>
            </xsl:if>
        </xsl:if>


        <!-- Se incluyo bloque en un For, como en Validador Java - Inicio - PrepaidPayment(Anticipos)-->
        <xsl:for-each select="cac:PrepaidPayment">
            <!-- Validar que si existe informacion en los campos mencionados anteriormente,
				debe ser numerico mayor a cero. Si no cumple marcar ERROR-2503. Validar que
				exista el tag de referencia al documento del anticipo. Si no cumple, marcar
				ERROR-2504 -->
            <!--JorgeS 180315 inicio -->
            <!-- Que el tag monto prepago o anticipado por documento sea mayor a cero.
			De no cumplir generar código de rechazo 2503 – PaidAmount: monto anticipado por documento debe ser mayor a cero -->
            <!-- <xsl:if test="./cbc:PaidAmount and (not(regexp:match(./cbc:PaidAmount,'^[0-9]{1,12}(\.[0-9]{1,2})?$')) or ./cbc:PaidAmount &lt;= 0 )"> -->
            <xsl:if test="./cbc:PaidAmount and ./cbc:PaidAmount &lt;= 0 ">
                <xsl:call-template name="addWarning"> <xsl:with-param name="warningCode" select="'2503'"/> <xsl:with-param name="warningMessage" select="concat('El monto de anticipo debe de ser mayor a cero, documento: ', position())"/></xsl:call-template>
                <!--<xsl:message terminate="yes" dp:priority="debug"> -->
                <xsl:message terminate="no" dp:priority="debug">
                    <xsl:value-of select="'Error Expr Regular Factura (codigo: 2503)'"/>
                </xsl:message>
            </xsl:if>
            <!--JorgeS 180315 fin -->
            <!-- Si se encuentra el tag /invoice/cac:PrepaidPayment/cbc:PaidAmount/
				validar que existan los tags /invoice/cac:PrepaidPayment/cbc:ID y /invoice/cac:PrepaidPayment/cbc:InstructionID
				.Si no cumple, marcar ERROR-2504 -->
            <!--JorgeS 180315 inicio -->
            <!-- Que existan el documento relacionado con los tag de ruc de emisor que solicita anticipo –de existir, tipo y número de documento de anticipo.
					De no existir marcar código de error 2504 -  Falta referencia de la factura relacionada con anticipo -->
            <!-- <xsl:if test="./cbc:PaidAmount and not(./cbc:ID and ./cbc:InstructionID)"> -->
            <xsl:if test="./cbc:PaidAmount and not(./cbc:ID and ./cbc:InstructionID)">
                <!--<xsl:call-template name="throwError"> -->
                <xsl:call-template name="addWarning"> <xsl:with-param name="warningCode" select="'2504'"/> <xsl:with-param name="warningMessage" select="concat('documento: ', position())"/></xsl:call-template>
                <!--<xsl:message terminate="yes" dp:priority="debug"> -->
                <xsl:message terminate="no" dp:priority="debug">
                    <xsl:value-of select="'Error Expr Regular Factura (codigo: 2504)'"/>
                </xsl:message>
            </xsl:if>
            <!--JorgeS 180315 fin -->
            <!--JorgeS 180315 inicio -->
            <!-- Validar que el campo /cac:PrepaidPayment/cbc:ID/@SchemeID exista y contenga información. De no corresponder
			generar código de excepción 1041 - cac:PrepaidPayment/cbc:ID - El tag no contiene el atributo @SchemeID que indica el
			tipo de documento que realiza el anticipo -->
            <!-- <xsl:if test="./cbc:PaidAmount and not(./cbc:ID and ./cbc:InstructionID)"> -->
            <xsl:if test="./cbc:ID/@schemeID and not(./cbc:ID/@schemeID != '')">
                <!--<xsl:call-template name="throwError"> -->
                <xsl:call-template name="addWarning"> <xsl:with-param name="warningCode" select="'1041'"/> <xsl:with-param name="warningMessage" select="concat('documento: ', position())"/></xsl:call-template>
                <!--<xsl:message terminate="yes" dp:priority="debug"> -->
                <xsl:message terminate="no" dp:priority="debug">
                    <xsl:value-of select="'Error Expr Regular Factura (codigo: 1041)'"/>
                </xsl:message>
            </xsl:if>
            <!--JorgeS 180315 fin -->
            <!-- /invoice/cac:PrepaidPayment/cbc:ID (Tipo de documento - Catalogo No.
				12) Validar que el tipo de documento de anticipo es el codigo 02 (catalogo
				12) /invoice/cac:PrepaidPayment/cbc:ID. Si no cumple, marcar ERROR-2505. -->
            <!--JorgeS 180315 inicio -->
            <!-- El tag cac:PrepaidPayment/cbc:ID/@SchemeID debe registrar el tipo de documento relacionado el código 02 o el código 03 (catalogo 12).
			De no corresponder generar código de rechazo 2505- cac:PrepaidPayment/cbc:ID/@SchemeID: código de referencia debe ser 02 o 03 -->
            <!-- <xsl:if test="./cbc:ID and not(./cbc:ID='02')"> -->
            <xsl:if test="./cbc:ID and ./cbc:ID/@schemeID !='02' and ./cbc:ID/@schemeID !='03'">
                <!--<xsl:call-template name="throwError">-->
                <xsl:call-template name="addWarning"> <xsl:with-param name="warningCode" select="'2505'"/> <xsl:with-param name="warningMessage" select="concat('documento: ', position())"/></xsl:call-template>
                <!--<xsl:message terminate="yes" dp:priority="debug">-->
                <xsl:message terminate="no" dp:priority="debug">
                    <xsl:value-of select="'Error Expr Regular Factura (codigo: 2505)'"/>
                </xsl:message>
            </xsl:if>
            <!--JorgeS 180315 fin -->
            <!-- Inicio js 130515-->
            <xsl:choose>
                <xsl:when test="./cbc:InstructionID/@schemeID">
                    <xsl:if test="not(./cbc:InstructionID/@schemeID != '')">
                        <xsl:call-template name="addWarning"> <xsl:with-param name="warningCode" select="'1042'"/> <xsl:with-param name="warningMessage" select="concat('documento: ', position())"/></xsl:call-template>
                    </xsl:if>
                    <!-- 					<xsl:if
						test='not(regexp:match(./cbc:ID,"^[F][A-Z0-9]{3}-[0-9]{1,8}$|^(E001)-[0-9]{1,8}$|^[B][A-Z0-9]{3}-[0-9]{1,8}$|^(EB01)-[0-9]{1,8}$"))'>   -->
                    <!--<xsl:call-template name="throwError">-->
                    <!-- 						<xsl:call-template name="throwError">
							<xsl:with-param name="codigo" select="'2506'" />
						</xsl:call-template>
						<xsl:message terminate="yes" dp:priority="debug"> -->
                    <!-- 						<xsl:message terminate="yes" dp:priority="debug">
							<xsl:value-of select="'Error Expr Regular Factura (codigo: 2506)'" />
						</xsl:message>
					</xsl:if>	 -->
                    <xsl:if test="./cbc:ID/@schemeID ='02' and not(regexp:match(./cbc:ID,'^[F][A-Z0-9]{3}-[0-9]{1,8}$|^(E001)-[0-9]{1,8}$|^[0-9]{1,4}-[0-9]{1,8}$'))">
                        <xsl:call-template name="addWarning"> <xsl:with-param name="warningCode" select="'2521'"/> <xsl:with-param name="warningMessage" select="concat('documento: ', position())"/></xsl:call-template>
                    </xsl:if>
                    <xsl:if test="./cbc:ID/@schemeID ='03' and not(regexp:match(./cbc:ID,'^[B][A-Z0-9]{3}-[0-9]{1,8}$|^[0-9]{1,4}-[0-9]{1,8}$'))">
                        <xsl:call-template name="addWarning"> <xsl:with-param name="warningCode" select="'2521'"/> <xsl:with-param name="warningMessage" select="concat('documento: ', position())"/></xsl:call-template>
                    </xsl:if>
                    <xsl:if test="./cbc:InstructionID/@schemeID != '6'">
                        <xsl:call-template name="addWarning"> <xsl:with-param name="warningCode" select="'2520'"/> <xsl:with-param name="warningMessage" select="concat('documento: ', position())"/></xsl:call-template>
                    </xsl:if>
                    <xsl:if test="./cbc:InstructionID = ''">
                        <xsl:call-template name="addWarning"> <xsl:with-param name="warningCode" select="'2529'"/> <xsl:with-param name="warningMessage" select="concat('documento: ', position())"/></xsl:call-template>
                    </xsl:if>
                    <xsl:if test="not(regexp:match(./cbc:InstructionID,'^[0-9]{11}$'))">
                        <xsl:call-template name="addWarning"> <xsl:with-param name="warningCode" select="'2521'"/> <xsl:with-param name="warningMessage" select="concat('documento: ', position())"/></xsl:call-template>
                    </xsl:if>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:if test="./cbc:InstructionID">
                        <xsl:if test="./cbc:InstructionID = ''">
                            <xsl:call-template name="addWarning"> <xsl:with-param name="warningCode" select="'2508'"/> <xsl:with-param name="warningMessage" select="concat('documento: ', position())"/></xsl:call-template>
                        </xsl:if>
                        <xsl:if test="not(regexp:match(./cbc:InstructionID,'^[F][A-Z0-9]{3}-[0-9]{1,8}$|^(E001)-[0-9]{1,8}$|^[0-9]{1,4}-[0-9]{1,8}$'))">
                            <!--				test="not(regexp:match(./cbc:InstructionID,'^[0-9]{11}$|^[-]{1}$'))"> -->
                            <xsl:call-template name="addWarning"> <xsl:with-param name="warningCode" select="'1044'"/> <xsl:with-param name="warningMessage" select="concat('documento: ', position())"/></xsl:call-template>
                        </xsl:if>
                    </xsl:if>
                </xsl:otherwise>
            </xsl:choose>
            <!-- Fin js 130515-->
        </xsl:for-each>
        <!-- Se incluyo bloque en un For, como en Validador Java - Fin -->


        <!-- Se incluye bloque para Errores 2508 y 2509 - Inicio -->
        <xsl:variable name="PrepaidPaymentId02GreaterThan0" select="count(cac:PrepaidPayment/cbc:ID[text()='02'])>0"/>
        <xsl:variable name="acumPrepaid">
            <xsl:call-template name="getPrepaidPaymentAcum">
                <xsl:with-param name="Items" select="cac:PrepaidPayment"/>
            </xsl:call-template>
        </xsl:variable>

		<xsl:choose>
		    <xsl:when test="$PrepaidPaymentId02GreaterThan0">
                <xsl:if test="cac:LegalMonetaryTotal/cbc:PrepaidAmount and not(regexp:match(cac:LegalMonetaryTotal/cbc:PrepaidAmount,'^[0-9]{1,12}(\.[0-9]{1,2})?$'))">
                    <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2509'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2509 -1)'" /> </xsl:call-template>
                </xsl:if>
                <xsl:if test="number(cac:LegalMonetaryTotal/cbc:PrepaidAmount) != number(round(100*$acumPrepaid) div 100)">
                    <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2509'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2509 -2)'" /> </xsl:call-template>
                </xsl:if>
            </xsl:when>
            <xsl:otherwise>
                <xsl:if test='cac:LegalMonetaryTotal/cbc:PrepaidAmount and cac:LegalMonetaryTotal/cbc:PrepaidAmount &lt;= 0'>
                    <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2508'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2508)'" /> </xsl:call-template>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>

		<!--JorgeS 190315 inicio -->
        <!-- De existir documento de anticipos se debe validar que exista el tag monto total anticipado. De no corresponder generara
			el código de excepción 1048 - El XML no contiene el tag o no existe información de PrepaidAmount para documentos con anticipos.-->
        <xsl:if test="cac:LegalMonetaryTotal/cbc:PrepaidAmount and not(cac:LegalMonetaryTotal/cbc:PrepaidAmount !='')">
            <xsl:call-template name="addWarning"> <xsl:with-param name="warningCode" select="'1048'"/> <xsl:with-param name="warningMessage" select="'Expr Regular Factura (codigo: 1048)'"/></xsl:call-template>
        </xsl:if>
        <!--JorgeS 190315 fin -->

        <!--JorgeS 190315 inicio -->
        <!-- Que el tag monto total anticipado sea mayor a cero. De no cumplir generar código de error 2527 – PrepaidAmount: monto total
			anticipado debe ser mayor a cero.-->
        <xsl:if test="cac:LegalMonetaryTotal/cbc:PrepaidAmount and cac:LegalMonetaryTotal/cbc:PrepaidAmount &lt;= 0">
            <xsl:call-template name="addWarning"> <xsl:with-param name="warningCode" select="'2527'"/> <xsl:with-param name="warningMessage" select="'Expr Regular Factura (codigo: 2527)'"/></xsl:call-template>
        </xsl:if>
        <!--JorgeS 190315 fin -->

        <!--JorgeS 190315 inicio -->
        <!-- Se incluye segun validadro Java -->
        <!-- 		<xsl:if test="cac:LegalMonetaryTotal/cbc:PrepaidAmount and (number(cac:LegalMonetaryTotal/cbc:PrepaidAmount) != number($acumPrepaid))">
			<xsl:call-template name="throwError">
				<xsl:with-param name="codigo" select="'2509'" />
			</xsl:call-template>
			<xsl:message terminate="yes" dp:priority="debug">
				<xsl:value-of select="'Error Expr Regular Factura (codigo: 2509)'" />
			</xsl:message>
		</xsl:if> -->
        <!-- Se incluyo bloque para Errores 2508 y 2509 - Fin -->
        <!--JorgeS 190315 fin -->
        <!-- Validar que la serie y numero del documento de anticipo corresponda
			a un documento emitido por anticipo (ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/sac:AdditionalInformation/sac:SUNATTransaction/cbc:ID
			= 04). Si no cumple, marcar ERROR-2507. <xsl:if test="not($sacSUNATTransactionID[text()
			= '04']) and (cac:PrepaidPayment/cbc:InstructionID)"> <xsl:call-template
			name="throwError"> <xsl:with-param name="codigo" select="'2507'" /> </xsl:call-template>
			<xsl:message terminate="yes" dp:priority="debug"> <xsl:value-of select="'Error
			Expr Regular Factura (codigo: 2507)'" /> </xsl:message> </xsl:if> -->
        <!-- fin comprobantes anticipados -->
        <!-- Numero del Documento del emisor - Nro RUC -->
        <!-- <xsl:value-of select="cac:AccountingSupplierParty/cbc:CustomerAssignedAccountID"/>
			muestra valor del tag XML -->
        <xsl:choose>
		     <xsl:when test="not(string(cac:AccountingSupplierParty/cbc:CustomerAssignedAccountID))">
                <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'1006'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 1006)'" /> </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:if test='not(regexp:match(cac:AccountingSupplierParty/cbc:CustomerAssignedAccountID,"^[0-9]{11}$"))'>
                    <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'1005'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 1005)'" /> </xsl:call-template>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>


        <!-- Numeracion, conformada por serie y numero correlativo del comprobante  -->
        <xsl:choose>
            <xsl:when test="not(string(cbc:ID))">
                <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'1002'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 1002)'" /> </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:if test='not(regexp:match(cbc:ID,"^[FS][A-Z0-9]{3}-[0-9]{1,8}?$"))'>
                    <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'1001'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 1001)'" /> </xsl:call-template>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
        <!-- <xsl:variable name="errores"> -->

        <!-- Tipo Comprobante -->
        <xsl:choose>
            <xsl:when test="not(string(cbc:InvoiceTypeCode))">
                <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'1004'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 1004)'" /> </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:if test='not(regexp:match(cbc:InvoiceTypeCode,"^(01|14)$"))'>
                    <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'1003'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 1003)'" /> </xsl:call-template>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>

        <!-- Version de la Estructura del Documento -->
        <xsl:choose>
            <xsl:when test="not(string(cbc:CustomizationID))">
                <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2073'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2073)'" /> </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:if test='not(regexp:match(cbc:CustomizationID,"^[0-9]{1,7}(\.[0-9]{1,2})?$"))'>
                    <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2072'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2072)'" /> </xsl:call-template>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>

        <!-- Version del UBL -->
        <xsl:choose>
            <xsl:when test="not(string(cbc:UBLVersionID))">
                <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2075'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2075)'" /> </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:if test='not(regexp:match(cbc:UBLVersionID,"^[2]{1}(\.[0]{1})$"))'>
                    <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2074'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2074)'" /> </xsl:call-template>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>

		<!-- JorgeS 190315 Dirección del emisor. Tag: /Invoice/cac:SellerSupplierParty/cac:Party/cac:PostalAddress/.. Inicio-->
        <!-- <xsl:for-each select="cac:SellerSupplierParty">	 -->
        <!-- De existir el tag cbc:AddressTypeCode no consignar información adicional en la dirección. De no cumplir generar código de
			observación 4046 - No debe consignar información adicional en la dirección para los locales anexos.De no existir el tag tag cbc:AddressTypeCode-->
        <!-- en stand by hasta proximo aviso 06/04/15-->
        <!-- 			<xsl:if
								test="not(cac:SellerSupplierParty/cac:Party/cac:PostalAddress/cbc:AddressTypeCode)">
								<xsl:call-template name="throwError">
									<xsl:with-param name="codigo" select="'4046'" />
								</xsl:call-template>
								<xsl:message terminate="yes" dp:priority="debug">
									<xsl:value-of select="'Error Expr Regular Factura (codigo: 4046)'" />
								</xsl:message>
							</xsl:if>	 -->
        <!--En stand by, validacion '4039' incorporada hasta proximo anio - Maribel (correo viernes 22-05-2015)-->
        <!-- Que exista el tag cbc:ID (ubigeo) y contenga información. De no cumplir generar código de observación 4039 – No ha consignado
			información del ubigeo del domicilio fiscal.-->
        <!-- 			<xsl:if
							test="cac:SellerSupplierParty/cac:Party/cac:PostalAddress/cbc:ID and not(cac:SellerSupplierParty/cac:Party/cac:PostalAddress/cbc:ID != '')">
							<xsl:call-template name="throwError">
								<xsl:with-param name="codigo" select="'4039'" />
							</xsl:call-template>
							<xsl:message terminate="yes" dp:priority="debug">
								<xsl:value-of select="'Error Expr Regular Factura (codigo: 4039)'" />
							</xsl:message>
						</xsl:if> -->
        <!-- a.3	de existir el código de ubigeo, este debe ser el mismo que el registrado en el campo ddp_ubigeo de la tabla ddp.
			De no cumplir generar código de observación 4012 – El ubigeo indicado en el comprobante no es el mismo que está registrado para el contribuyente. (Tablas) -->
        <!-- De existir el tag cac:Country/cbc:IdentificationCode el valor del campo debe ser igual a PE. De no cumplir generar
			código de observación 4041 - El código de país debe ser PE.-->

		<!-- Ubicacion de pais PE -->
        <xsl:if test="cac:SellerSupplierParty/cac:Party/cac:PostalAddress/cac:Country/cbc:IdentificationCode and cac:SellerSupplierParty/cac:Party/cac:PostalAddress/cac:Country/cbc:IdentificationCode[text()!='PE']">
            <xsl:call-template name="addWarning"> <xsl:with-param name="warningCode" select="'4041'"/> <xsl:with-param name="warningMessage" select="'El codigo de pais debe de ser PE'"/></xsl:call-template>
        </xsl:if>

        <!-- </xsl:for-each> -->
        <!-- JorgeS 190315 Dirección del emisor. Tag: /Invoice/cac:SellerSupplierParty/cac:Party/cac:PostalAddress/.. Fin-->
        <!-- Tipo de documento de identidad del emisor - RUC -->
        <xsl:if test="not(string(cac:AccountingSupplierParty/cbc:AdditionalAccountID))">
            <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'1008'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 1008)'" /> </xsl:call-template>
        </xsl:if>
        <xsl:if test='not(regexp:match(cac:AccountingSupplierParty/cbc:AdditionalAccountID,"^[6]{1}$"))'>
            <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'1007'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 1007)'" /> </xsl:call-template>
        </xsl:if>
        <xsl:if test="count(cac:AccountingSupplierParty/cbc:AdditionalAccountID)>1">
            <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2362'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2362)'" /> </xsl:call-template>
        </xsl:if>
        <!-- Tipo de moneda en la cual se emite la factura electronica -->
        <xsl:choose>
            <xsl:when test="not(string(cbc:DocumentCurrencyCode))">
                <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2070'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2070)'" /> </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:if test='not(regexp:match(cbc:DocumentCurrencyCode,"^[A-Z]{3}$"))'>
                    <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2069'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2069)'" /> </xsl:call-template>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>

		<!-- Apellidos y nombres o denominacion o razon social Emisor -->
        <xsl:choose>
            <xsl:when test="not(string(cac:AccountingSupplierParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName))">
                <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'1037'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 1037)'" /> </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:if test='not(regexp:match(cac:AccountingSupplierParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName,"^(?!\s*$).{3,1000}"))'>
                    <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'1038'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 1038)'" /> </xsl:call-template>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>

		<!-- Valida que el tipo de documento del adquiriente exista -->
        <xsl:if test="not(string(cac:AccountingCustomerParty/cbc:AdditionalAccountID))">
            <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2015'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular FACTURA (codigo: 2015)'" /> </xsl:call-template>
        </xsl:if>

	    <!-- Valida que el tipo de documento del adquiriente exista y sea solo uno -->
        <xsl:if test="count(cac:AccountingCustomerParty/cbc:AdditionalAccountID)>1">
            <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2363'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular FACTURA (codigo: 2363)'" /> </xsl:call-template>
        </xsl:if>




        <!-- Si la operacion (Códigos de Tipo de Afectación del IGV) no es de exportacion (40) el tipo de documento tiene que ser 6, caso contrario -->
<!--         <xsl:choose>
            <xsl:when test="cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cbc:TaxExemptionReasonCode[text()='40']">
                <xsl:if test='not(regexp:match(cac:AccountingCustomerParty/cbc:AdditionalAccountID,"^[01467A\-]{1}$"))'>
                    <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2016'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular FACTURA (codigo: 2016)'" /> </xsl:call-template>
                </xsl:if>

            </xsl:when>

            <xsl:otherwise>
                <xsl:if test='not(cac:AccountingCustomerParty/cbc:AdditionalAccountID[text()="6"])'>
                    <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2016'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular FACTURA (codigo: 2016_01)'" /> </xsl:call-template>
                </xsl:if>

            </xsl:otherwise>

        </xsl:choose> -->


        <xsl:choose>
            <xsl:when test="cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cbc:TaxExemptionReasonCode[text()='40']">
                <xsl:if test='not(regexp:match(cac:AccountingCustomerParty/cbc:AdditionalAccountID,"^[01467A\-]{1}$"))'>
                    <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2016'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular FACTURA (codigo: 2016)'" /> </xsl:call-template>
                </xsl:if>

            </xsl:when>
            <xsl:otherwise>
				<!--30/11/2016-JSoria - Renta Neta/ inicio -->
				<!--COND: Identifica que se trata de una operacion de Renta Neta -->
				<xsl:if test="$sacSUNATTransactionID[text()='13']">

						 <xsl:if test="not(cac:AccountingCustomerParty/cbc:AdditionalAccountID[text()='1' or text()='6'])">
							<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2800'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular FACTURA, debe ingresar AdditionalAccountID 1 o 6(codigo: 2800)'" /></xsl:call-template>
						</xsl:if>

						<xsl:if test="cac:AccountingCustomerParty/cbc:AdditionalAccountID[text()='1'] and not(regexp:match(cac:AccountingCustomerParty/cbc:CustomerAssignedAccountID,'^[0-9]{8}$'))">
							<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2801'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular FACTURA, debe ingresar numeracion correcta de DNI CustomerAssignedAccountID(codigo: 2801)'" /></xsl:call-template>
						</xsl:if>

						<xsl:if test="cac:AccountingCustomerParty/cbc:AdditionalAccountID[text()='6'] and not(regexp:match(cac:AccountingCustomerParty/cbc:CustomerAssignedAccountID,'^[0-9]{11}$'))">
							<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2802'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular FACTURA, debe ingresar numeracion correcta de RUC CustomerAssignedAccountID(codigo: 2802)'" /></xsl:call-template>
						</xsl:if>

					<!-- 					<xsl:variable name ="digitoverificadormod11">
							<xsl:call-template name="checkDigit">
								<xsl:with-param name="XX" select="concat('10',substring(cac:AccountingCustomerParty/cbc:CustomerAssignedAccountID,1,8)"/>
							</xsl:call-template>
						</xsl:variable>
						<xsl:if test="$digitoverificadormod11 != substring(cac:AccountingSupplierParty/cbc:CustomerAssignedAccountID,9,1)">
							<xsl:call-template name="rejectCall">
								<xsl:with-param name="errorCode" select="'2804'"/>
								<xsl:with-param name="errorMessage" select="'DNI no valido(codigo: 2804)'"/>
							</xsl:call-template>
						</xsl:if>	 -->

				</xsl:if>
            </xsl:otherwise>
        </xsl:choose>



        <xsl:if test='not($sacSUNATTransactionID[text()="13"]) and cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cbc:TaxExemptionReasonCode[text()!="40"]'>
			<xsl:if test='not(cac:AccountingCustomerParty/cbc:AdditionalAccountID[text()=6])'>
						<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2016'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular FACTURA (codigo: 2016)'" /> </xsl:call-template>
			</xsl:if>
        </xsl:if>


        <!-- Apellidos y nombres o denominacion o razon social del adquirente o usuario -->
        <xsl:choose>
            <xsl:when test="not(string(cac:AccountingCustomerParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName))">
                <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2021'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2021)'" /> </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:if test='not(regexp:match(cac:AccountingCustomerParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName,"^(?!\s*$).{3,1000}"))'>
                    <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2022'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2022)'" /> </xsl:call-template>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>

		<!-- Importe total de la venta, cesion en uso o del servicio prestado -->
        <xsl:choose>
            <xsl:when test="not(cac:LegalMonetaryTotal/cbc:PayableAmount)">
                <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2063'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2063)'" /> </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:if test='not(regexp:match(cac:LegalMonetaryTotal/cbc:PayableAmount,"^[0-9]{1,12}(\.[0-9]{1,10})?$"))'>
                    <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2062'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2062)'" /> </xsl:call-template>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>

	   <!-- Sumatoria otros Cargos -->
        <xsl:if test="cac:LegalMonetaryTotal/cbc:ChargeTotalAmount">
            <xsl:if test='not(regexp:match(cac:LegalMonetaryTotal/cbc:ChargeTotalAmount,"^[0-9]{1,12}(\.[0-9]{1,2})?$"))'>
                <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2064'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2064)'" /> </xsl:call-template>
            </xsl:if>
        </xsl:if>

		<!-- Descuentos Globales -->
        <xsl:if test="cac:LegalMonetaryTotal/cbc:AllowanceTotalAmount">
            <!-- MOver a la parte del detalle -->
            <xsl:if test='not(regexp:match(cac:LegalMonetaryTotal/cbc:AllowanceTotalAmount,"^[0-9]{1,12}(\.[0-9]{1,2})?$"))'>
                <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2065'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2065)'" /> </xsl:call-template>
            </xsl:if>
            <!-- fin mover al detalle -->
            <xsl:if test='not(regexp:match(cac:LegalMonetaryTotal/cbc:AllowanceTotalAmount,"^[0-9]{1,12}(\.[0-9]{1,2})?$"))'>
                <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2419'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2419)'" /> </xsl:call-template>
            </xsl:if>
        </xsl:if>

        <!-- Se incluyo bloque en un For, como en Validador Java - Inicio -->
        <xsl:for-each select="cac:DespatchDocumentReference">
            <!-- Documento de referencia -->
            <xsl:if test="./cbc:DocumentTypeCode">
                <xsl:choose>
                    <xsl:when test='not(regexp:match(./cbc:DocumentTypeCode,"^[0-9]{2}$"))'>
                        <xsl:call-template name="addWarning"> <xsl:with-param name="warningCode" select="'4004'"/> <xsl:with-param name="warningMessage" select="concat('documento: ', position())"/></xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:if test="not((./cbc:DocumentTypeCode=09) or (./cbc:DocumentTypeCode=31))">
                            <xsl:call-template name="addWarning"> <xsl:with-param name="warningCode" select="'4005'"/> <xsl:with-param name="warningMessage" select="concat('documento: ', position())"/></xsl:call-template>
                        </xsl:if>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:if>
            <xsl:if test="./cbc:DocumentTypeCode">
                <xsl:choose>
                    <xsl:when test='not(./cbc:ID)'>
                        <xsl:call-template name="addWarning"> <xsl:with-param name="warningCode" select="'4007'"/> <xsl:with-param name="warningMessage" select="concat('documento: ', position())"/></xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:if test='not(regexp:match(./cbc:ID,"^(.){1,}-[0-9]{1,}$"))'>
                            <xsl:call-template name="addWarning"> <xsl:with-param name="warningCode" select="'4006'"/> <xsl:with-param name="warningMessage" select="concat('documento: ', position())"/></xsl:call-template>
                        </xsl:if>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:if>
        </xsl:for-each>

		<!-- Se incluyo bloque en un For, como en Validador Java - Fin -->
        <xsl:for-each select="cac:DespatchDocumentReference">
            <xsl:if test="count(key('by-document-despatch-reference', concat(./cbc:DocumentTypeCode,' ',./cbc:ID))) > 1">
                <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2364'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura  (codigo: 2364)'" /> </xsl:call-template>
            </xsl:if>
        </xsl:for-each>

	    <!-- <xsl:if test="cac:DespatchDocumentReference/cbc:DocumentTypeCode">
			<xsl:if
				test="(cac:DespatchDocumentReference/cbc:DocumentTypeCode=09 or cac:DespatchDocumentReference/cbc:DocumentTypeCode=31) and (count(cac:DespatchDocumentReference/cbc:DocumentTypeCode)>1 or count(cac:DespatchDocumentReference/cbc:ID)>1)">
				<xsl:call-template name="throwError">
					<xsl:with-param name="codigo" select="'2364'" />
				</xsl:call-template>
				<xsl:message terminate="yes" dp:priority="debug">
					<xsl:value-of select="'Error Expr Regular Factura (codigo: 2364)'" />
				</xsl:message>
			</xsl:if>
		</xsl:if> -->
        <!-- Otros documentos relacionados -->

		<!-- Se incluyo bloque en un For, como en Validador Java - Inicio -->
        <xsl:for-each select="cac:AdditionalDocumentReference">
            <xsl:if test="./cbc:DocumentTypeCode">
                <xsl:choose>
                    <xsl:when test='not(regexp:match(./cbc:DocumentTypeCode,"^[0-9]{2}$"))'>
                        <xsl:call-template name="addWarning"> <xsl:with-param name="warningCode" select="'4008'"/> <xsl:with-param name="warningMessage" select="concat('documento: ', position())"/></xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:if test="not((./cbc:DocumentTypeCode=04) or (./cbc:DocumentTypeCode=05) or (./cbc:DocumentTypeCode=99) or (./cbc:DocumentTypeCode=01))">
                            <xsl:call-template name="addWarning"> <xsl:with-param name="warningCode" select="'4009'"/> <xsl:with-param name="warningMessage" select="concat('documento: ', position())"/></xsl:call-template>
                        </xsl:if>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:if>
            <xsl:choose>
                <xsl:when test='./cbc:DocumentTypeCode and not(./cbc:ID)'>
                    <xsl:call-template name="addWarning"> <xsl:with-param name="warningCode" select="'4011'"/> <xsl:with-param name="warningMessage" select="concat('documento: ', position())"/></xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:if test='./cbc:DocumentTypeCode and not(regexp:match(./cbc:ID,"^(?!\s*$).{1,100}"))'>
                        <xsl:call-template name="addWarning"> <xsl:with-param name="warningCode" select="'4010'"/> <xsl:with-param name="warningMessage" select="concat('documento: ', position())"/></xsl:call-template>
                    </xsl:if>
                </xsl:otherwise>
            </xsl:choose>
            <!-- Comentado y remplazado por key con conteo -->
            <!-- <xsl:if
				test="(./cbc:DocumentTypeCode=04 or ./cbc:DocumentTypeCode=05 or ./cbc:DocumentTypeCode=99 or ./cbc:DocumentTypeCode=01) and (count(./cbc:DocumentTypeCode)>1 or count(./cbc:ID)>1)">
				<xsl:call-template name="throwError">
					<xsl:with-param name="codigo" select="'2365'" />
				</xsl:call-template>
				<xsl:message terminate="yes" dp:priority="debug">
					<xsl:value-of select="'Error Expr Regular Factura (codigo: 2365)'" />
				</xsl:message>
			</xsl:if>-->
        </xsl:for-each>

	   <!-- Se incluyo bloque en un For, como en Validador Java - Fin -->
	    <xsl:for-each select="cac:AdditionalDocumentReference">
            <xsl:if test="count(key('by-document-additional-reference', concat(./cbc:DocumentTypeCode,' ',./cbc:ID))) > 1">
                <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2365'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura  (codigo: 2365)'" /> </xsl:call-template>
            </xsl:if>
        </xsl:for-each>
        <!-- Se incluyo bloque en un For, como en Validador Java - Fin -->


        <!-- Sumatoria IGV / ISC / Otros Tributos -->
        <xsl:if test="cac:TaxTotal/cbc:TaxAmount">
            <xsl:choose>
                <xsl:when test="not(string(cac:TaxTotal/cbc:TaxAmount))">
                    <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2049'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2049)'" /> </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:if test='not(regexp:match(cac:TaxTotal/cbc:TaxAmount,"^[0-9]{1,12}(\.[0-9]{1,2})?$"))'>
                        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2048'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2048)'" /> </xsl:call-template>
                    </xsl:if>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:for-each select="cac:TaxTotal">
                <xsl:if test='./cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID=1000'>
                    <xsl:if test="count(./cbc:TaxAmount)>1">
                        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2352'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2352)'" /> </xsl:call-template>
                    </xsl:if>
                </xsl:if>
                <xsl:if test='./cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID=2000'>
                    <xsl:if test="count(./cbc:TaxAmount)>1">
                        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2353'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2353)'" /> </xsl:call-template>
                    </xsl:if>
                </xsl:if>
                <xsl:if test='./cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID=9999'>
                    <xsl:if test="count(./cbc:TaxAmount)>1">
                        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2354'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2354)'" /> </xsl:call-template>
                    </xsl:if>
                </xsl:if>
            </xsl:for-each>
        </xsl:if>

	    <!-- Validaciones TaxSchema -->
        <xsl:variable name="taxSubtotalTaxCategoryTaxScheme" select="cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme"/>
        <xsl:if test="$taxSubtotalTaxCategoryTaxScheme">
            <xsl:choose>
                <xsl:when test="not($taxSubtotalTaxCategoryTaxScheme/cbc:ID)">
                    <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2052'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2052)'" /> </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:if test='not(regexp:match($taxSubtotalTaxCategoryTaxScheme/cbc:ID,"^[0-9]{4}$"))'>
                        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2050'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2050)'" /> </xsl:call-template>
                    </xsl:if>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:if test="not((($taxSubtotalTaxCategoryTaxScheme/cbc:ID)='1000') or (($taxSubtotalTaxCategoryTaxScheme/cbc:ID)='2000') or (($taxSubtotalTaxCategoryTaxScheme/cbc:ID)='9999'))">
                <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2051'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2051)'" /> </xsl:call-template>
            </xsl:if>
            <xsl:choose>
                <xsl:when test="not($taxSubtotalTaxCategoryTaxScheme/cbc:Name)">
                    <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2054'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2054)'" /> </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:if test='not(regexp:match($taxSubtotalTaxCategoryTaxScheme/cbc:Name,"^(?!\s*$)[^\s]{3,1000}"))'>
                        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2053'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2053)'" /> </xsl:call-template>
                    </xsl:if>
                </xsl:otherwise>
            </xsl:choose>
            <!-- Campo opcional, Antes expresion regular era ^(?!\s*$)[^\s]{3,100}$ -->
            <xsl:if test='$taxSubtotalTaxCategoryTaxScheme/cbc:TaxTypeCode and not(regexp:match($taxSubtotalTaxCategoryTaxScheme/cbc:TaxTypeCode,"^(\s*$)|(.*)?[^\s]{3,100}"))'>
                <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2055'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2055)'" /> </xsl:call-template>
            </xsl:if>
            <!-- MAguilar 03062016 -->
			<!-- Se reemplazo: xsl:if test="(($taxSubtotalTaxCategoryTaxScheme/cbc:ID=1000) and $taxSubtotalTaxCategoryTaxScheme/cbc:TaxTypeCode !='' and $taxSubtotalTaxCategoryTaxScheme/cbc:TaxTypeCode and not($taxSubtotalTaxCategoryTaxScheme/cbc:Name='IGV'))"-->
            <xsl:if test="(($taxSubtotalTaxCategoryTaxScheme/cbc:ID=1000) and $taxSubtotalTaxCategoryTaxScheme/cbc:TaxTypeCode !='' and $taxSubtotalTaxCategoryTaxScheme/cbc:TaxTypeCode and not($taxSubtotalTaxCategoryTaxScheme/cbc:Name='IGV' or $taxSubtotalTaxCategoryTaxScheme/cbc:Name='IVAP'))">
                <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2057'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2057)'" /> </xsl:call-template>
            </xsl:if>
            <xsl:if test="(($taxSubtotalTaxCategoryTaxScheme/cbc:ID=1000) and $taxSubtotalTaxCategoryTaxScheme/cbc:TaxTypeCode !='' and $taxSubtotalTaxCategoryTaxScheme/cbc:TaxTypeCode and not($taxSubtotalTaxCategoryTaxScheme/cbc:TaxTypeCode='VAT'))">
                <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2057'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2057)'" /> </xsl:call-template>
            </xsl:if>
            <xsl:if test="(($taxSubtotalTaxCategoryTaxScheme/cbc:ID=2000) and $taxSubtotalTaxCategoryTaxScheme/cbc:TaxTypeCode !='' and $taxSubtotalTaxCategoryTaxScheme/cbc:TaxTypeCode and not($taxSubtotalTaxCategoryTaxScheme/cbc:Name='ISC'))">
                <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2058'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2058)'" /> </xsl:call-template>
            </xsl:if>
            <xsl:if test="(($taxSubtotalTaxCategoryTaxScheme/cbc:ID=2000) and $taxSubtotalTaxCategoryTaxScheme/cbc:TaxTypeCode !='' and $taxSubtotalTaxCategoryTaxScheme/cbc:TaxTypeCode and not($taxSubtotalTaxCategoryTaxScheme/cbc:TaxTypeCode='EXC'))">
                <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2058'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2058)'" /> </xsl:call-template>
            </xsl:if>
        </xsl:if>
        <!-- fin Validaciones TaxSchema -->

		<xsl:if test="cac:TaxTotal/cac:TaxSubtotal/cbc:TaxAmount">
            <xsl:for-each select="cac:TaxTotal">
                <xsl:choose>
                    <xsl:when test="not(string(./cac:TaxSubtotal/cbc:TaxAmount))">
                        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2060'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2060)'" /> </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:if test='not(regexp:match(./cac:TaxSubtotal/cbc:TaxAmount,"^[0-9]{1,12}(\.[0-9]{1,2})?$"))'>
                            <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2059'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2059)'" /> </xsl:call-template>
                        </xsl:if>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:if test="number(./cac:TaxSubtotal/cbc:TaxAmount)!=number(./cbc:TaxAmount)">
                    <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2061'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2061)'" /> </xsl:call-template>
                </xsl:if>
                <xsl:if test="$sacSUNATTransactionID[text() = '04'] and (./cac:TaxSubtotal/cbc:TaxAmount[text()&lt;=0])">
                    <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2502'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2502)'" /> </xsl:call-template>
                </xsl:if>
            </xsl:for-each>
        </xsl:if>

		<!-- TODO: quiza haga falta realizar un for-each Verificar con detenimiento
			cac:PricingReference/cac:AlternativeConditionPrice -->

		<xsl:if test="(cbc:DocumentCurrencyCode!=$sacAdditionalInformation/sac:AdditionalMonetaryTotal/cbc:ID[text()!='2001' or text()!='2003']/../cbc:PayableAmount/@currencyID)">
            <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2071'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2071)'" /> </xsl:call-template>
        </xsl:if>
        <!-- Validacion no se encuentra en java

		<xsl:if
			test="(cbc:DocumentCurrencyCode!=cac:LegalMonetaryTotal/cbc:PayableAmount/@currencyID) or (cbc:DocumentCurrencyCode!=cac:TaxTotal/cbc:TaxAmount/@currencyID) or (cbc:DocumentCurrencyCode!=cac:TaxTotal/cac:TaxSubtotal/cbc:TaxAmount/@currencyID) or (cbc:DocumentCurrencyCode!=cac:LegalMonetaryTotal/cbc:ChargeTotalAmount/@currencyID) or (cbc:DocumentCurrencyCode!=cac:InvoiceLine/cac:PricingReference/cac:AlternativeConditionPrice/cbc:PriceAmount/@currencyID) or (cbc:DocumentCurrencyCode!=cac:InvoiceLine/cac:Price/cbc:PriceAmount/@currencyID) or (cbc:DocumentCurrencyCode!=cac:InvoiceLine/cbc:LineExtensionAmount/@currencyID) or (cbc:DocumentCurrencyCode!=cac:InvoiceLine/cac:TaxTotal/cbc:TaxAmount/@currencyID) or (cbc:DocumentCurrencyCode!=cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal/cbc:TaxAmount/@currencyID) or (cbc:DocumentCurrencyCode!=cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal/cbc:TaxAmount/@currencyID)">
			<xsl:call-template name="throwError">
				<xsl:with-param name="codigo" select="'2071'" />
			</xsl:call-template>
			<xsl:message terminate="yes" dp:priority="debug">
				<xsl:value-of select="'Error Expr Regular Factura (codigo: 2071)'" />
			</xsl:message>
		</xsl:if>
		-->



		<!-- Valida que el numero de documento del adquirente existe y si es RUC
			valida que conste de 11 caracteres numericos -->
        <xsl:choose>
            <xsl:when test="not(string(cac:AccountingCustomerParty/cbc:CustomerAssignedAccountID))">
                <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2014'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular FACTURA (codigo: 2014)'" /> </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:if test="cac:AccountingCustomerParty/cbc:AdditionalAccountID[text()='6'] and not(regexp:match(cac:AccountingCustomerParty/cbc:CustomerAssignedAccountID,'^[0-9]{11}$|^[-]{1}$'))">
                    <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2017'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular FACTURA (codigo: 2017)'" /> </xsl:call-template>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>

	   <!-- Firma Digital de Documento -->
        <xsl:choose>
            <xsl:when test="not((cac:Signature/cbc:ID))">
                <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2076'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2076)'" /> </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:if test='not(regexp:match(cac:Signature/cbc:ID,"^(?!\s*$).{2,3000}"))'>
                    <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2077'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2077)'" /> </xsl:call-template>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:if test="not(cac:Signature/cac:SignatoryParty/cac:PartyIdentification/cbc:ID)">
            <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2079'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2079)'" /> </xsl:call-template>
        </xsl:if>
        <!-- xsl:if test="(cac:Signature/cac:SignatoryParty/cac:PartyIdentification/cbc:ID != cac:AccountingSupplierParty/cbc:CustomerAssignedAccountID)">
            <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2078'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2078)'" /> </xsl:call-template>
        </xsl:if -->
        <xsl:choose>
            <xsl:when test="not(cac:Signature/cac:SignatoryParty/cac:PartyName/cbc:Name)">
                <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2081'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2081)'" /> </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:if test='not(regexp:match(cac:Signature/cac:SignatoryParty/cac:PartyName/cbc:Name,"^(?!\s*$).{2,3000}"))'>
                    <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2080'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2080)'" /> </xsl:call-template>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:choose>
            <xsl:when test="not(cac:Signature/cac:DigitalSignatureAttachment/cac:ExternalReference/cbc:URI)">
                <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2083'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2083)'" /> </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:if test='not(regexp:match(cac:Signature/cac:DigitalSignatureAttachment/cac:ExternalReference/cbc:URI,"^(?!\s*$).{2,3000}"))'>
                    <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2082'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2082)'" /> </xsl:call-template>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
		<xsl:choose>
            <xsl:when test="not((ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/ds:Signature/@Id))">
                <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2085'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2085)'" /> </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:if test='not(regexp:match(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/ds:Signature/@Id,"^(?!\s*$).{2,3000}"))'>
                    <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2084'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2084)'" /> </xsl:call-template>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:choose>
            <xsl:when test="not(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/ds:Signature/ds:SignedInfo/ds:CanonicalizationMethod/@Algorithm)">
                <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2087'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2087)'" /> </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:if test='not(regexp:match(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/ds:Signature/ds:SignedInfo/ds:CanonicalizationMethod/@Algorithm,"^(?!\s*$).{2,3000}"))'>
                    <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2086'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2086)'" /> </xsl:call-template>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:choose>
            <xsl:when test="not(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/ds:Signature/ds:SignedInfo/ds:SignatureMethod/@Algorithm)">
                <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2089'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2089)'" /> </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:if test='not(regexp:match(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/ds:Signature/ds:SignedInfo/ds:SignatureMethod/@Algorithm,"^(?!\s*$).{2,3000}"))'>
                    <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2088'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2088)'" /> </xsl:call-template>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:choose>
            <xsl:when test="not(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/ds:Signature/ds:SignedInfo/ds:Reference/@URI)">
                <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2091'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2091)'" /> </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:if test='string(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/ds:Signature/ds:SignedInfo/ds:Reference/@URI)'>
                    <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2090'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2090)'" /> </xsl:call-template>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:choose>
            <xsl:when test="not(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/ds:Signature/ds:SignedInfo/ds:Reference/ds:Transforms/ds:Transform/@Algorithm)">
                <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2093'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2093)'" /> </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:if test='not(regexp:match(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/ds:Signature/ds:SignedInfo/ds:Reference/ds:Transforms/ds:Transform/@Algorithm,"^(?!\s*$).{2,3000}"))'>
                    <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2092'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2092)'" /> </xsl:call-template>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:choose>
            <xsl:when test="not(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/ds:Signature/ds:SignedInfo/ds:Reference/ds:DigestMethod/@Algorithm)">
                <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2095'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2095)'" /> </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:if test='not(regexp:match(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/ds:Signature/ds:SignedInfo/ds:Reference/ds:DigestMethod/@Algorithm,"^(?!\s*$).{2,3000}"))'>
                    <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2094'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2094)'" /> </xsl:call-template>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:choose>
            <xsl:when test="not(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/ds:Signature/ds:SignedInfo/ds:Reference/ds:DigestValue)">
                <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2097'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2097)'" /> </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
				<!-- <xsl:if test='not(regexp:match(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/ds:Signature/ds:SignedInfo/ds:Reference/ds:DigestValue,"^(?!\s*$).{2,3000}"))'>
					<xsl:call-template name="throwError"><xsl:with-param name="codigo" select="'2096'"/></xsl:call-template><xsl:message
					terminate="yes" dp:priority="debug"><xsl:value-of select="'Error Expr Regular
					Factura (codigo: 2096)'"/></xsl:message> </xsl:if> -->
			</xsl:otherwise>
        </xsl:choose>
        <xsl:choose>
            <xsl:when test="not(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/ds:Signature/ds:SignatureValue)">
                <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2099'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2099)'" /> </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:if test='not(regexp:match(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/ds:Signature/ds:SignatureValue,"[A-Za-z0-9+/=\s]{2,}"))'>
                    <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2098'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2098)'" /> </xsl:call-template>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:choose>
            <xsl:when test="not(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/ds:Signature/ds:KeyInfo/ds:X509Data/ds:X509Certificate)">
                <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2101'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2101)'" /> </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:if test='not(regexp:match(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/ds:Signature/ds:KeyInfo/ds:X509Data/ds:X509Certificate,"[A-Za-z0-9+/=\s]{2,}"))'>
                    <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2100'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2100)'" /> </xsl:call-template>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>



		<!--27/10/2015-Maguilar - Exportacion con operaciones gratuitas (Global)/ inicio -->
			<!--COND: Identifica que se trata de una operacion de exportacion -->
			<xsl:if test="$sacSUNATTransactionID[text()='02']">
					<!--COND: si e la operacion de exportacion hay al menos un item marcado como gratuito -->
					<xsl:if test="count(cac:InvoiceLine[cac:PricingReference/cac:AlternativeConditionPrice/cbc:PriceTypeCode='02'])>0">
					<!--VAL 4: Informacion Adicional - Otros conceptos tributarios  Catálogo No. 14 / Valor 1004  de venir y este debe ser mayor a 0-->
						<xsl:if test="number(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/sac:AdditionalInformation/sac:AdditionalMonetaryTotal[cbc:ID=1004]/cbc:PayableAmount) = 0
						or not(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/sac:AdditionalInformation/sac:AdditionalMonetaryTotal[cbc:ID=1004]/cbc:PayableAmount)">
							<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2641'" /> <xsl:with-param name="errorMessage" select="'Operacion gratuita,  debe consignar Total valor venta - operaciones gratuitas  mayor a cero (codigo: 2641)'" /> </xsl:call-template>
						</xsl:if>
					</xsl:if>
					<!--VAL 2: Precio Unitario : Todos los precios unitarios deben ser del tipo 02	(Valor referencial unitario en operaciones no onerosas) Catalogo 16 -->
					<!--ERR: Operacion gratuita debe tener el Tipo de Precio  de todos los items igual a 02 -->
					<!--
					<xsl:if test="count(cac:InvoiceLine[cac:PricingReference/cac:AlternativeConditionPrice/cbc:PriceTypeCode!='02'])>0">
						<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2573'" /> <xsl:with-param name="errorMessage" select="'Operacion gratuita debe tener el Tipo de Precio de todos los items igual a 02(codigo: 2573)'" /> </xsl:call-template>
					</xsl:if>
					-->
					<!--VAL 3: Informacion Adicional - Otros conceptos tributarios  Catálogo No. 14 / Valor 1004  de venir otro tag que no sea 1004 y estos de venir deben estar en cero-->
					<!--ERR: Operacion gratuita no acepta informacion adicional de otros conceptos tributarios distintos de Total valor de venta – Operaciones gratuitas -->
					<!--
					<xsl:if test="sum(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/sac:AdditionalInformation/sac:AdditionalMonetaryTotal[cbc:ID!='1004']/cbc:PayableAmount)>0">
						<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2574'" /> <xsl:with-param name="errorMessage" select="'Operacion gratuita solo acepta valores para Total valor venta del tipo 1004 mayores a cero (codigo: 2574)'" /> </xsl:call-template>
					</xsl:if>
					-->
					<!--VAL 5: Tipo de Afectación al IGV de todos los items debe ser 40-->
					<!--
					<xsl:if test="count(cac:InvoiceLine[cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cbc:TaxExemptionReasonCode[text() != '40']])>0">
						<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2642'" /> <xsl:with-param name="errorMessage" select="'Operacion gratuita exportacion debe marcar todos sus items con Tipo Afectacion igual a 40 (codigo: 2642)'" /> </xsl:call-template>
					</xsl:if>
					-->
			</xsl:if>
		<!--27/10/2015-Exportacion con operaciones gratuitas / fin -->

		<!--27/10/2015-Maguilar - IVAP / inicio -->
		<!--COND: Para un tipo de operacion IVAP -->
		<xsl:if test="ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/sac:AdditionalInformation/sac:SUNATTransaction/cbc:ID=07">
			<!--VAL 1:Todo Item debe tener impuesto>0  , para ello se cuentan todos los items que tengan 0 en monto -->
			<!--ERR: Debe consignar Monto de impuestos-->
			<xsl:if test="count(cac:InvoiceLine[cac:TaxTotal/cac:TaxSubtotal/cbc:TaxAmount=0])">
				<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2643'" /> <xsl:with-param name="errorMessage" select="'Factura de operacion sujeta IVAP debe consignar Monto de impuestos por item(codigo: 2643)'" /> </xsl:call-template>
			</xsl:if>
			<!--VAL 2:Todo Item debe tener codigo de afectacion en 17  , para ello se cuentan todos los items que sean diferentes de 17 -->
			<xsl:if test="count(cac:InvoiceLine[cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cbc:TaxExemptionReasonCode!=17])">
				<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2644'" /> <xsl:with-param name="errorMessage" select="'Factura de operacion sujeta IVAP solo debe tener ítems con código afectación IGV 17(codigo: 2644)'" /> </xsl:call-template>
			</xsl:if>
			<!--VAL 3:Todo Item debe tener codigo de afectacion en 17  y codigo tributo 1000 , para ello se cuentan todos los items que sean diferentes de 1000 -->
			<xsl:if test="count(cac:InvoiceLine[cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID!=1000])">
				<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2645'" /> <xsl:with-param name="errorMessage" select="'Factura de operacion sujeta a IVAP debe consignar items con codigo de tributo 1000(codigo: 2645)'" /> </xsl:call-template>
			</xsl:if>
			<!--VAL 4:Todo Item debe tener codigo de afectacion en 17 y Tipo IVAP  , para ello se cuentan todos los items que sean diferentes de 1000 -->
			<xsl:if test="count(cac:InvoiceLine[cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:Name!='IVAP'])">
				<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2646'" /> <xsl:with-param name="errorMessage" select="'Factura de operacion sujeta a IVAP debe consignar  items con nombre  de tributo IVAP(codigo: 2646)'" /> </xsl:call-template>
			</xsl:if>
			<!--VAL 5:Todo Item debe tener Tipo de codigo de afectacion VAT , para ello se cuentan todos los items que sean diferentes de VAT -->
			<xsl:if test="count(cac:InvoiceLine[cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:TaxTypeCode!='VAT'])">
				<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2647'" /> <xsl:with-param name="errorMessage" select="'Código tributo  UN/ECE debe ser VAT(codigo: 2647)'" /> </xsl:call-template>
			</xsl:if>
			<!--VAL 6:Total valor de venta - operaciones gravadas /Código de tipo de monto -  Catálogo No. 14 / Valor 1001  ** Se suman aquellos valores que sean diferentes de 1001-->
			<xsl:if test="sum(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/sac:AdditionalInformation/sac:AdditionalMonetaryTotal[cbc:ID!='1001']/cbc:PayableAmount)>0">
				<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2648'" /> <xsl:with-param name="errorMessage" select="'Factura de operacion sujeta al IVAP, solo puede consignar informacion para operacion gravadas(codigo: 2648)'" /> </xsl:call-template>
			</xsl:if>
			<!--VAL 7:MOnto de IGV debe ser mayor que cero  -->
			<xsl:if test="sum(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/sac:AdditionalInformation/sac:AdditionalMonetaryTotal[cbc:ID=1001]/cbc:PayableAmount)=0">
				<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2649'" /> <xsl:with-param name="errorMessage" select="'Operación sujeta al IVAP, debe consignar monto en total operaciones gravadas(codigo: 2649)'" /> </xsl:call-template>
			</xsl:if>
			<!--VAL 8:Monto de ISC debe ser cero o no venir -->
			<xsl:if test="cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme[cbc:ID=2000]/../../cbc:TaxAmount>0">
				<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2650'" /> <xsl:with-param name="errorMessage" select="'Factura de operacion sujeta al IVAP , no debe consignar valor para ISC o debe ser 0(codigo: 2650)'" /> </xsl:call-template>
			</xsl:if>
			<!--VAL 9:Dato de Leyenda debe llegar con 2007 , no exclusivo -->
			<!-- MAguilar 03062016 -->
			<!-- Se reemplazo :xsl:if test="ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/sac:AdditionalInformation/sac:AdditionalProperty/cbc:ID!=’2007’"-->
			<xsl:if test="count(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/sac:AdditionalInformation/sac:AdditionalProperty[cbc:ID=2007])=0">
				<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2651'" /> <xsl:with-param name="errorMessage" select="'Factura de operacion sujeta al IVAP , debe registrar mensaje 2007(codigo: 2651)'" /> </xsl:call-template>
			</xsl:if>
		</xsl:if>
		<!--27/10/2015 - IVAP / fin -->



			<!--06/12/2016 - JS Validacion AdditionalProperty / INI-->
<!-- 		     <xsl:if test="not($sacAdditionalInformation/sac:AdditionalProperty/cbc:ID[text() = '1000' or text() = '1002' or text() = '2000' or text() = '2001' or text() = '2002' or text() = '2003' or text() = '2004' or text() = '2005' or text() = '3000' or text() = '3001' or text() = '3002' or text() = '3003' or text() = '3004' or text() = '3005' or text() = '3006' or text() = '3007' or text() = '3008' or text() = '3009' or text() = '3010' or text() = '4000' or text() = '4001' or text() = '4002' or text() = '4003' or text() = '4004' or text() = '4005' or text() = '4006' or text() = '4007' or text() = '4008' or text() = '4009' or text() = '5000' or text() = '5001' or text() = '5002' or text() = '5003' or text() = '6000' or text() = '6001' or text() = '6002' or text() = '6003' or text() = '6004'])">

                <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'xxxx'"/> <xsl:with-param name="errorMessage" select="concat('el valor: ', AdditionalProperty, ' no se encuentra en el catalogo 15 (codigo: xxxx)')"/></xsl:call-template>

            </xsl:if> -->
			<!--06/12/2016 - JS Validacion AdditionalProperty / FIN -->





		<!--27/10/2015-Maguilar - Exportacion de un no Domiciliado /Inicio-->
		<!-- Se probo que acepte IGV a nivel global y de item y es valido sin modificar
			 Por ello solo se agregan las restricciones puntuales para este caso
			 La identificacoin de que se trata de un exportacion en este caso esta en funcion de las lineas -->
			<!--COND:Siempre que se tenga un item con 40 exportacion y 1000 IGV IVA -->
		<xsl:variable name="itemsExportacion" select="
			    cac:InvoiceLine[cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cbc:TaxExemptionReasonCode='40'
			and cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID='1000'
			and cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:Name='IGV'
			and cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:TaxTypeCode='VAT']" />
			<xsl:if test="count($itemsExportacion)>0">
				<!--COND: Para los casos en los que el tipo de documento del adquiriente es 0 No domiciliado  -->
				<xsl:if test="cac:AccountingCustomerParty/cbc:AdditionalAccountID=0">
					<!--VAL 1:El Monto del IGV a nivel de totales debe permitir y ser mayor a cero  -->
					<!--ERR : Exportacion de un no domiciliado - Monto del IGV a nivel de totales debe ser mayor a cero  -->
					<!--
					<xsl:if test="
					not(cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID='1000' and
					cac:TaxTotal/cac:TaxSubtotal/cbc:TaxAmount >= 0)">

						<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2653'" /> <xsl:with-param name="errorMessage" select="'Servicios prestados No domiciliados. Total IGV debe se mayor a cero(codigo: 2653)'" /> </xsl:call-template>
					</xsl:if>
					-->
					<!--VAL 2 :Los tipos de impuesto a utilizar deben ser Cod Trib 1000 -->
					<!--ERR : Exportacion de un no domiciliado - Todos los items deben ser marcados como exportacion cod 1000  -->

					<xsl:if test="count(cac:InvoiceLine[cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID!='1000'])>0">
						<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2654'" /> <xsl:with-param name="errorMessage" select="'Servicios prestados No domiciliados. Código tributo a consignar debe ser 1000(codigo: 2654)'" /> </xsl:call-template>
					</xsl:if>

					<!--VAL 3 :Los tipos de impuesto a utilizar deben ser marcados como exportacion 40  -->
					<!--ERR Codigo de tributo no corresponde-->

					<xsl:if test="count(cac:InvoiceLine[cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cbc:TaxExemptionReasonCode!='40'])>0">
						<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2655'" /> <xsl:with-param name="errorMessage" select="'Servicios prestados No domiciliados.  El código de afectación debe ser 40(codigo: 2655)'" /> </xsl:call-template>
					</xsl:if>

					<!--VAL 4 :Los tipos de impuesto a utilizar deben ser marcados Tipo codigo VAT  -->
					<!--ERR Codigo de tributo no corresponde-->

					<xsl:if test="count(cac:InvoiceLine[cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:TaxTypeCode!='VAT'])>0">
						<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2656'" /> <xsl:with-param name="errorMessage" select="'Servicios prestados No domiciliados. Código tributo  UN/ECE debe ser VAT (codigo: 2656)'" /> </xsl:call-template>
					</xsl:if>

				</xsl:if>
			</xsl:if>
		<!--27/10/2015 - Exportacion de un no Domiciliado/ fin -->

        <!-- Detalle Factura -->
        <xsl:for-each select="cac:InvoiceLine">

        	<xsl:if test="count(key('by-invoiceLine-id', number(cbc:ID))) > 1">
                <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2752'" /> <xsl:with-param name="errorMessage" select="concat('El numero de item esta duplicado: ', cbc:ID)" /> </xsl:call-template>
            </xsl:if>

			<!--27/10/2015-Maguilar - Exportacion con operaciones gratuitas (Item) / inicio -->
			<xsl:choose>
				<!--COND: Identifica que se trata de una operacion de exportacion a nivel de tipo de operacion-->
				<xsl:when test="$sacSUNATTransactionID[text()='02']">
					<!--COND: Si el tipo de linea es onerosa , porque asi lo indica el precio-->
					<!--VAL 1: El tipo de afectacion de IGV debe ser 40 para la exportacion sea o no un item gratuito-->
					<xsl:if test="cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cbc:TaxExemptionReasonCode[text() != '40']">
						<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2642'" /> <xsl:with-param name="errorMessage" select="'Operaciones de exportacion, deben consignar Tipo Afectacion igual a 40 (codigo: 2642)'" /> </xsl:call-template>
					</xsl:if>
					<!--COND: Si el tipo de linea es gratuita , porque asi lo indica el precio-->
					<xsl:if test='cac:PricingReference/cac:AlternativeConditionPrice/cbc:PriceTypeCode = 02'>
						<!--VAL 2: Valor unitario : de las operaciones gratuitas debe ser cero -->
						<xsl:if test="cac:Price/cbc:PriceAmount>0">
							<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2640'" /> <xsl:with-param name="errorMessage" select="'Operacion gratuita, solo debe consignar un monto referencial  (codigo: 2640)'" /> </xsl:call-template>
						</xsl:if>
					</xsl:if>
				</xsl:when>
			</xsl:choose>
			<!--27/10/2015-Maguilar - Exportacion con operaciones gratuitas (Item) / final -->
            <!-- Numero de orden del Item -->
            <xsl:choose>
                <xsl:when test="not(./cbc:ID)">
                    <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2023'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2023)'" /> </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:if test='not(regexp:match(./cbc:ID,"^[0-9]{1,3}?$")) or ./cbc:ID &lt;= 0'>
                        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2023'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2023)'" /> </xsl:call-template>
                    </xsl:if>
                </xsl:otherwise>
            </xsl:choose>

			<!-- Cantidad de unidades por item -->
            <xsl:choose>
                <xsl:when test="not(string(./cbc:InvoicedQuantity))">
                    <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2024'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2024)'" /> </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:if test='not(regexp:match(./cbc:InvoicedQuantity,"^[0-9]{1,12}(\.[0-9]{1,10})?$"))'>
                        <!-- 17/09/2014 se corrigio la cantidad de decimales, decia 3 -->
                        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2025'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2025)'" /> </xsl:call-template>
                    </xsl:if>
                </xsl:otherwise>
            </xsl:choose>

            <!-- Descripcion detallada del servicio prestado, bien vendido o cedido en uso, indicando las caracteristicas -->
            <xsl:choose>
                <xsl:when test="not(./cac:Item/cbc:Description)">
                    <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2026'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2026)'" /> </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:if test='not(regexp:match(./cac:Item/cbc:Description,"^(?!\s*$).{1,250}"))'>
                        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2027'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2027)'" /> </xsl:call-template>
                    </xsl:if>
                </xsl:otherwise>
            </xsl:choose>
            <!-- Precio de venta unitario por item y codigo -->
            <!-- Realizar las validaciones dentro de un for-each cac:PricingReference/cac:AlternativeConditionPrice -->
            <xsl:for-each select="./cac:PricingReference/cac:AlternativeConditionPrice">
                <xsl:choose>
                    <xsl:when test="(./cbc:PriceTypeCode)=01 and (not(string(./cbc:PriceAmount)))">
                        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2028'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2028)'" /> </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:if test='(./cbc:PriceTypeCode)=01 and not(regexp:match(./cbc:PriceAmount,"^[0-9]{1,12}(\.[0-9]{1,10})?$"))'>
                            <!-- 17/09/2014 se corrigio la cantidad de decimales a 10 -->
                            <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2367'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2367)'" /> </xsl:call-template>
                        </xsl:if>
                    </xsl:otherwise>
                </xsl:choose>
                <!-- Precio de venta unitario por item -->
                <xsl:if test="(count(./cbc:PriceTypeCode[text()='01'])>1 or count(./cbc:PriceTypeCode[text()='02'])>1)">
                    <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2409'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2409)'" /> </xsl:call-template>
                </xsl:if>
                <xsl:if test="not(./cbc:PriceTypeCode=01 or ./cbc:PriceTypeCode=02)">
                    <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2410'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2410)'" /> </xsl:call-template>
                </xsl:if>
                <!-- actualizado 27/01/2014 fin -->
                <!-- Valor referencial unitario por item en operaciones no onerosas y codigo -->
                <xsl:choose>
                    <xsl:when test="(./cbc:PriceTypeCode)=02 and (not(string(./cbc:PriceAmount)))">
                        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2417'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2417)'" /> </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:if test='(./cbc:PriceTypeCode)=02 and not(regexp:match(./cbc:PriceAmount,"^[0-9]{1,12}(\.[0-9]{1,10})?$"))'>
                            <!-- 16/01/2014 se corrigio la cantidad de decimales, decia 10 lo correcto es 2 -->
                            <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2408'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2408)'" /> </xsl:call-template>
                        </xsl:if>
                    </xsl:otherwise>
                </xsl:choose>
                <!-- <xsl:if test='(./cbc:PriceTypeCode)=02 and (./cbc:PriceAmount<0
					)'> <xsl:call-template name="throwError"> <xsl:with-param name="codigo" select="'2418'"
					/> </xsl:call-template> <xsl:message terminate="yes" dp:priority="debug">
					<xsl:value-of select="'Error Expr Regular Factura (codigo: 2418)'" /> </xsl:message>
					</xsl:if> -->
            </xsl:for-each>
            <!-- fin de for-each cac:PricingReference/cac:AlternativeConditionPrice -->
            <!-- Equivalente a flag debehabervalorreferencial de validador java -->
            <!-- <xsl:variable name="debehabervalorreferencial" select="./cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID=1000 and (count(./cac:TaxSubtotal/cac:TaxCategory/cbc:TaxExemptionReasonCode[text() != '10' or text() != '20' or text() != '30' or text() != '40'])>1)"/> -->
            <!-- <xsl:variable name="debehabervalorreferencial" select="./cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID[text()='1000'] and (count(./cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cbc:TaxExemptionReasonCode[text() != '10' and text() != '20' and text() != '30' and text() != '40'])>1)"/> -->
            <!-- xsl:if test="$debehabervalorreferencial">
				<xsl:for-each select="./cac:PricingReference/cac:AlternativeConditionPrice" -->
            <!-- Valor referencial unitario por item en operaciones no onerosas y codigo -->
            <!-- xsl:choose>
						<xsl:when test="(./cbc:PriceTypeCode)=02 and (not(string(./cbc:PriceAmount)))">
							<xsl:call-template name="throwError">
								<xsl:with-param name="codigo" select="'2417'" />
							</xsl:call-template>
							<xsl:message terminate="yes" dp:priority="debug">
								<xsl:value-of select="'Error Expr Regular Factura (codigo: 2417)'" />
							</xsl:message>
						</xsl:when>
						<xsl:otherwise>
							<xsl:if test='(./cbc:PriceTypeCode)=02 and not(regexp:match(./cbc:PriceAmount,"^[0-9]{1,12}(\.[0-9]{1,2})?$"))'>
								<xsl:call-template name="throwError">
									<xsl:with-param name="codigo" select="'2408'" />
								</xsl:call-template>
								<xsl:message terminate="yes" dp:priority="debug">
									<xsl:value-of select="'Error Expr Regular Factura (codigo: 2408)'" />
								</xsl:message>
							</xsl:if>
							<xsl:if test='(./cbc:PriceTypeCode)=02 and (./cbc:PriceAmount[text()&lt;=0])'>
								<xsl:call-template name="throwError">
									<xsl:with-param name="codigo" select="'2417'" />
								</xsl:call-template>
								<xsl:message terminate="yes" dp:priority="debug">
									<xsl:value-of select="'Error Expr Regular Factura (codigo: 2417)'" />
								</xsl:message>
							</xsl:if>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:for-each>
			</xsl:if -->
            <!-- Se incluye error 2408 y 2418 -->
            <!-- xsl:for-each select="./cac:PricingReference/cac:AlternativeConditionPrice" -->
            <!-- Valor referencial unitario por item en operaciones no onerosas y codigo -->
            <!-- xsl:choose>
					<xsl:when test='(./cbc:PriceTypeCode)=02 and not(regexp:match(./cbc:PriceAmount,"^[0-9]{1,12}(\.[0-9]{1,2})?$"))'>
						<xsl:call-template name="throwError">
							<xsl:with-param name="codigo" select="'2408'" />
						</xsl:call-template>
						<xsl:message terminate="yes" dp:priority="debug">
							<xsl:value-of select="'Error Expr Regular Factura (codigo: 2408)'" />
						</xsl:message>
					</xsl:when>
					<xsl:otherwise>
						<xsl:if test='(./cbc:PriceTypeCode)=02 and (./cbc:PriceAmount[text()&gt;0]) and not($debehabervalorreferencial)'>
							<xsl:call-template name="throwError">
								<xsl:with-param name="codigo" select="'2418'" />
							</xsl:call-template>
							<xsl:message terminate="yes" dp:priority="debug">
								<xsl:value-of select="'Error Expr Regular Factura (codigo: 2418)'" />
							</xsl:message>
						</xsl:if>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:for-each -->
            <xsl:choose>
                <xsl:when test="not(./cac:Price/cbc:PriceAmount)">
                    <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2068'" /> <xsl:with-param name="errorMessage" select="concat('Error Expr Regular Factura (codigo: 2068) line: ', cbc:ID)" /> </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                    <!-- Valor unitario por item -->
                    <xsl:if test='regexp:match(./cac:Price/cbc:PriceAmount,"^[\s]+$")'>
                        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2067'" /> <xsl:with-param name="errorMessage" select="concat('Error Expr Regular Factura (codigo: 2067) line: ', cbc:ID)" /> </xsl:call-template>
                    </xsl:if>
                    <xsl:if test='not(regexp:match(./cac:Price/cbc:PriceAmount,"^[0-9]{1,12}(\.[0-9]{1,10})?$"))'>
                        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2369'" /> <xsl:with-param name="errorMessage" select="concat('Error Expr Regular Factura (codigo: 2369) line: ', cbc:ID)" /> </xsl:call-template>
                    </xsl:if>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:choose>
                <xsl:when test="not(./cbc:LineExtensionAmount)">
                    <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2032'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2032)'" /> </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                    <!-- Valor de venta por item -->
                    <xsl:if test='regexp:match(./cbc:LineExtensionAmount,"^[\s]+$")'>
                        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2031'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2031)'" /> </xsl:call-template>
                    </xsl:if>
                    <xsl:if test='not(regexp:match(./cbc:LineExtensionAmount,"(-?[0-9]+){1,12}(\.[0-9]{1,2})?$"))'>
                        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2370'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2370)'" /> </xsl:call-template>
                    </xsl:if>
                </xsl:otherwise>
            </xsl:choose>
            <!-- Se incluye errores 2500 y 2501 en for-each - Inicio -->
            <xsl:if test="$sacSUNATTransactionID[text() = '04'] and (not(./cbc:LineExtensionAmount) or not(./cac:Item/cbc:Description))">
                <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2500'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2500)'" /> </xsl:call-template>
            </xsl:if>
            <xsl:if test="$sacSUNATTransactionID[text() = '04'] and (./cbc:LineExtensionAmount[text()&lt;=0])">
                <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2501'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2501)'" /> </xsl:call-template>
            </xsl:if>
            <!-- Se incluye errores 2500 y 2501 en for-each - Fin -->

			<!-- Operaciones gratuitas aplicada a toda operacion gratuita-->
			<xsl:if test="count(./cac:PricingReference/cac:AlternativeConditionPrice/cbc:PriceAmount[text()>0 and parent::node()/cbc:PriceTypeCode=02])>0
				and ./cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cbc:TaxExemptionReasonCode[text() = '10' or text() = '20' or text() = '30']">
				<xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2425'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2425)'" /> </xsl:call-template>
			</xsl:if>

            <!-- Afectacion al IGV por item - Sistema de ISC por item -->
            <!-- actualizado 16/01/2014 inicio -->
            <xsl:for-each select="./cac:TaxTotal">
                <xsl:if test='./cbc:TaxAmount'>
                    <xsl:choose>
                        <xsl:when test="not(string(./cbc:TaxAmount))">
                            <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2034'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2034)'" /> </xsl:call-template>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:if test='not(regexp:match(./cbc:TaxAmount,"^[0-9]{1,12}(\.[0-9]{1,2})?$"))'>
                                <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2033'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2033)'" /> </xsl:call-template>
                            </xsl:if>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:if test="./cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID=1000 and count(./cbc:TaxAmount)>1">
                        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2355'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2355)'" /> </xsl:call-template>
                    </xsl:if>
                    <xsl:if test="./cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID=2000 and count(./cbc:TaxAmount)>1">
                        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2356'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2356)'" /> </xsl:call-template>
                    </xsl:if>
                    <xsl:if test="number(./cbc:TaxAmount)!=number(./cac:TaxSubtotal/cbc:TaxAmount)">
                        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2372'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2372)'" /> </xsl:call-template>
                    </xsl:if>
                </xsl:if>
                <xsl:choose>
                    <xsl:when test="not(./cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID)">
                        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2037'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2037)'" /> </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:if test='not(regexp:match(./cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID,"^[0-9]{4}$"))'>
                            <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2035'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2035)'" /> </xsl:call-template>
                        </xsl:if>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:if test="not(./cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID[text()=1000 or text()=2000 or text()=9999])">
                    <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2036'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2036)'" /> </xsl:call-template>
                </xsl:if>
                <xsl:if test='./cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID=1000'>
                    <xsl:choose>
                        <xsl:when test="not(./cac:TaxSubtotal/cac:TaxCategory/cbc:TaxExemptionReasonCode)">
                            <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2371'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2371)'" /> </xsl:call-template>
                        </xsl:when>
                        <xsl:otherwise>
							<!--27/10/2015-Maguilar - IVAP /inicio
                            <xsl:if test="not(./cac:TaxSubtotal/cac:TaxCategory/cbc:TaxExemptionReasonCode[text() = '10' or text() = '11' or text() = '12' or text() = '13' or text() = '14' or text() = '15' or text() = '16' or text() = '20' or text() = '21' or text() = '30' or text() = '31' or text() = '32' or text() = '33' or text() = '34' or text() = '35' or text() = '36' or text() = '40'])">
                                <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2040'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2040)'" /> </xsl:call-template>
                            </xsl:if>
							27/10/2015-Maguilar - IVAP / fin
							Siguiente tag registra el cambio
							-->
							<xsl:if test="not(./cac:TaxSubtotal/cac:TaxCategory/cbc:TaxExemptionReasonCode[text() = '10' or text() = '11' or text() = '12' or text() = '13' or text() = '14' or text() = '15' or text() = '16' or text() = '17' or text() = '20' or text() = '21' or text() = '30' or text() = '31' or text() = '32' or text() = '33' or text() = '34' or text() = '35' or text() = '36' or text() = '40'])">
                                <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2040'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2040)'" /> </xsl:call-template>
                            </xsl:if>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:if>
                <xsl:choose>
                    <xsl:when test="not(./cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:Name)">
                        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2038'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2038)'" /> </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:if test='not(regexp:match(./cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:Name,"^[A-Z]{3,1000}?$"))'>
                            <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2038'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2038)'" /> </xsl:call-template>
                        </xsl:if>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:if test='./cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID'>
                    <xsl:if test='./cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID=1000'>
                        <xsl:if test="./cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:Name and ./cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:Name !='' and (not(./cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:Name='IGV') and not(./cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:TaxTypeCode='VAT'))">
                            <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2377'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2377)'" /> </xsl:call-template>
                        </xsl:if>
                    </xsl:if>
                    <xsl:if test='./cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID=2000'>
                        <xsl:if test="./cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:Name and ./cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:Name !='' and (not(./cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:Name='ISC') and not(./cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:TaxTypeCode='EXC'))">
                            <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2378'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2378)'" /> </xsl:call-template>
                        </xsl:if>
                    </xsl:if>
                </xsl:if>
                <xsl:if test="./cac:TaxSubtotal/cbc:TaxAmount">
                    <xsl:choose>
                        <xsl:when test="./cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID=1000 and not(string(./cac:TaxSubtotal/cbc:TaxAmount))">
                            <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2042'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2042)'" /> </xsl:call-template>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:if test='not(regexp:match(./cac:TaxSubtotal/cbc:TaxAmount,"^[0-9]{1,12}(\.[0-9]{1,2})?$"))'>
                                <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2368'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2368)'" /> </xsl:call-template>
                            </xsl:if>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:if>
                <xsl:if test='./cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID=2000'>
                    <xsl:if test="not(string(./cac:TaxSubtotal/cac:TaxCategory/cbc:TierRange))  and ./cac:TaxTotal/cbc:TaxAmount > 0">
                        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2373'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2373)'" /> </xsl:call-template>
                    </xsl:if>
                    <xsl:if test="./cac:TaxSubtotal/cac:TaxCategory/cbc:TierRange and not(./cac:TaxSubtotal/cac:TaxCategory/cbc:TierRange[text()='' or text()=01 or text()=02 or text()=03])">
                        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2041'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2041)'" /> </xsl:call-template>
                    </xsl:if>
                </xsl:if>
            </xsl:for-each>
            <!-- Ini: Validaciones referentes al IGV y ISC -->
            <!-- actualizado 12/05/2014 inicio -->
            <!-- Si es con IGV -->
            <!-- PU: <xsl:value-of select="./cac:PricingReference/cac:AlternativeConditionPrice/cbc:PriceAmount"/>
				VU: <xsl:value-of select="./cac:Price/cbc:PriceAmount"/> -->
            <!-- Si el precio unitario es menor al valor unitario -->
            <!-- se quito puesto que la validacion no existe en el sistema anterior
				<xsl:choose> <xsl:when test='./cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cbc:TaxExemptionReasonCode=10'>
				<xsl:if test='./cac:PricingReference/cac:AlternativeConditionPrice/cbc:PriceAmount
				&lt; ./cac:Price/cbc:PriceAmount'> <xsl:call-template name="throwError">
				<xsl:with-param name="codigo" select="'2426'" /> </xsl:call-template> <xsl:message
				terminate="yes" dp:priority="debug"> <xsl:value-of select="'Error Expr Regular
				Factura (codigo: 2426)'" /> </xsl:message> </xsl:if> </xsl:when> -->
            <!-- Si es con ISC -->
            <!-- <xsl:otherwise> <xsl:if test="./cac:TaxTotal/cac:TaxSubtotal/cbc:TaxAmount&lt;=0">
				<xsl:call-template name="throwError"> <xsl:with-param name="codigo" select="'2368'"
				/> </xsl:call-template> <xsl:message terminate="yes" dp:priority="debug">
				<xsl:value-of select="'Error Expr Regular Factura (codigo: 2368)'" /> </xsl:message>
				</xsl:if> </xsl:otherwise> </xsl:choose> -->
            <!-- Fin: Validaciones referentes al IGV y ISC -->
        </xsl:for-each>
        <!-- Sumatoria ISC error 2423 - Inicio -->
        <!-- xsl:if test="cac:TaxTotal/cbc:TaxAmount">
			<xsl:for-each select="cac:TaxTotal">
				<xsl:if test='./cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID=2000'>
					<xsl:if test="(count(./cbc:TaxAmount)=1) and (./cbc:TaxAmount[text() &lt;=0])">
						<xsl:call-template name="throwError">
							<xsl:with-param name="codigo" select="'2423'" />
						</xsl:call-template>
						<xsl:message terminate="yes" dp:priority="debug">
							<xsl:value-of select="'Error Expr Regular Factura (codigo: 2423)'" />
						</xsl:message>
					</xsl:if>
				</xsl:if>
			</xsl:for-each>
		</xsl:if -->
        <!-- Sumatoria ISC error 2423 - Fin -->
        <!-- js _ RF07 Datos que permitan a la factura la posibilidad de traslado de bienes, según el reglamento de comprobantes vigentes _ Inicio -->
        <xsl:for-each select="$sacAdditionalInformation/sac:SUNATEmbededDespatchAdvice">
            <xsl:if test="$sacSUNATTransactionID[text() = '06']">
                <!-- a.1 + a.2 -->
                <xsl:variable name="todoNulo" select="not(./cac:DeliveryAddress/cbc:ID) and not(./cac:DeliveryAddress/cbc:StreetName) and not(./cac:DeliveryAddress/cbc:CityName)
						and not(./cac:DeliveryAddress/cbc:CountrySubentity) and not(./cac:DeliveryAddress/cbc:District) and not(./cac:DeliveryAddress/cac:Country/cbc:IdentificationCode)
						and not(./cac:OriginAddress/cbc:ID) and not(./cac:OriginAddress/cbc:StreetName) and not(./cac:OriginAddress/cbc:CityName) and not(./cac:OriginAddress/cbc:CountrySubentity)
						and not(./cac:OriginAddress/cbc:District) and not(./cac:OriginAddress/cac:Country/cbc:IdentificationCode) "/>
                <xsl:if test="not($todoNulo)">
                    <xsl:if test="not(./cac:DeliveryAddress/cbc:ID != '' and ./cac:DeliveryAddress/cbc:StreetName != '' and ./cac:DeliveryAddress/cbc:CityName != ''
							and ./cac:DeliveryAddress/cbc:CountrySubentity != '' and ./cac:DeliveryAddress/cbc:District != '' and ./cac:DeliveryAddress/cac:Country/cbc:IdentificationCode != ''
							and ./cac:OriginAddress/cbc:ID != '' and ./cac:OriginAddress/cbc:StreetName != '' and ./cac:OriginAddress/cbc:CityName != '' and ./cac:OriginAddress/cbc:CountrySubentity != ''
							and ./cac:OriginAddress/cbc:District != '' and ./cac:OriginAddress/cac:Country/cbc:IdentificationCode != '')">
                        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2421'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2421)'" /> </xsl:call-template>
                    </xsl:if>
                </xsl:if>
                <!-- a.1	Debe de existir el tag de dirección de punto de partida.
					De no cumplir generar código de rechazo 2421 - Debe indicar  toda la información de  sustento de traslado de bienes. -->
                <!-- 					<xsl:if
						test="not(./cac:OriginAddress)">
						<xsl:call-template name="throwError">
							<xsl:with-param name="codigo" select="'2421'" />
						</xsl:call-template>
						<xsl:message terminate="yes" dp:priority="debug">
							<xsl:value-of select="'Error Expr Regular Factura (codigo: 2421 -1)'" />
						</xsl:message>
					</xsl:if> -->
                <!-- a.2	Debe de existir el tag de dirección de punto de llegada.
					De no cumplir generar código de rechazo 2421 - Debe indicar  toda la información de  sustento de traslado de bienes. -->
                <!-- 					<xsl:if
						test="not(./cac:DeliveryAddress)">
						<xsl:call-template name="throwError">
							<xsl:with-param name="codigo" select="'2421'" />
						</xsl:call-template>
						<xsl:message terminate="yes" dp:priority="debug">
							<xsl:value-of select="'Error Expr Regular Factura (codigo: 2421 -2)'" />
						</xsl:message>
					</xsl:if> -->
                <!-- a.3	Debe de existir el tag de modalidad de transporte.
					De no cumplir generar código de error 2532 - No existe información de modalidad de transporte. -->
                <xsl:if test="not(./cbc:TransportModeCode)">
                    <xsl:call-template name="addWarning"> <xsl:with-param name="warningCode" select="'2532'"/> <xsl:with-param name="warningMessage" select="'Expr Regular Factura (codigo: 2532)'"/></xsl:call-template>
                </xsl:if>
                <!-- js_080715 a.4  El tag modalidad de transporte (cbc: TransportModeCode) debe ser = 01 o 02, de no cumplir generar código de  WARNING TEMPORAL EN LUGAR DE ERROR  4043 – Para el TransportModeCode, se está usando un valor que no existe en el catálogo Nro. 18. -->
                <xsl:if test="./cbc:TransportModeCode and ./cbc:TransportModeCode[text() != '01'] and ./cbc:TransportModeCode[text() != '02']">
                    <xsl:call-template name="addWarning"> <xsl:with-param name="warningCode" select="'4043'"/> <xsl:with-param name="warningMessage" select="'Expr Regular Factura (codigo: 4043)'"/></xsl:call-template>
                </xsl:if>
                <!-- a.5 Trasporte Privado cbc:TransportModeCode 02 -->
                <xsl:if test="./cbc:TransportModeCode and ./cbc:TransportModeCode[text() = '02']">
                    <!-- a.5.1 Debe existir los tags siguientes:
					-	Placa del vehículo
					-	N° constancia de inscripción del vehículo o certificado de habilitación vehicular
					-	Marca del vehículo
					-	Licencia de conducir
					De no cumplir generar código de error 2533 – Si ha consignado Transporte Privado, debe consignar Licencia de conducir,
					Placa, N° constancia de inscripción y marca del vehículo.  -->
                    <xsl:variable name="Tags1" select="./sac:SUNATRoadTransport/cbc:LicensePlateID and ./sac:SUNATRoadTransport/cbc:TransportAuthorizationCode and ./sac:SUNATRoadTransport/cbc:BrandName and ./sac:DriverParty/cac:Party/cac:PartyIdentification/cbc:ID"/>
                    <xsl:if test="not($Tags1)">
                        <xsl:call-template name="addWarning"> <xsl:with-param name="warningCode" select="'2533'"/> <xsl:with-param name="warningMessage" select="'Expr Regular Factura (codigo: 2533)'"/></xsl:call-template>
                    </xsl:if>
                    <!-- a.5.2 No Debe existir los tags siguientes:
					-	RUC
					-	Nombre o Razón Social
					De no cumplir generar código de observación 4045 - No es necesario consignar los datos del transportista para la modalidad
					de transporte 02 – Transporte Privado. -->
                    <xsl:if test="./sac:SUNATCarrierParty/cbc:CustomerAssignedAccountID and ./sac:SUNATCarrierParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName">
                        <xsl:call-template name="addWarning"> <xsl:with-param name="warningCode" select="'4045'"/> <xsl:with-param name="warningMessage" select="'Expr Regular Factura (codigo: 4045)'"/></xsl:call-template>
                    </xsl:if>
                </xsl:if>
                <!-- a.6 Trasporte Publico cbc:TransportModeCode 01 -->
                <xsl:if test="./cbc:TransportModeCode and ./cbc:TransportModeCode[text() = '01']">
                    <!-- a.6.1 Debe existir los tags siguientes:
					-	RUC
					-	Nombre o Razón Social
					De no cumplir generar código de error 2534 – Si ha consignado Transporte púbico, debe consignar Datos del transportista. -->
                    <xsl:if test="not(./sac:SUNATCarrierParty/cbc:CustomerAssignedAccountID and ./sac:SUNATCarrierParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName)">
                        <xsl:call-template name="addWarning"> <xsl:with-param name="warningCode" select="'2534'"/> <xsl:with-param name="warningMessage" select="'Expr Regular Factura (codigo: 2534)'"/></xsl:call-template>
                    </xsl:if>
                </xsl:if>
                <!-- a.7 cbc:GrossWeightMeasure -->
                <xsl:if test="./cbc:GrossWeightMeasure">
                    <!-- a.7.1   De existir el tag se debe validar que el campo @unitCode exista y tenga información.
					De no cumplir generar código de EXCEP 0306. -->
                    <xsl:if test="./cbc:GrossWeightMeasure/@unitCode and ./cbc:GrossWeightMeasure/@unitCode = ''">
                        <xsl:call-template name="addWarning"> <xsl:with-param name="warningCode" select="'0306'"/> <xsl:with-param name="warningMessage" select="'Expr Regular Factura (codigo: 0306)'"/></xsl:call-template>
                    </xsl:if>
                    <!-- a.7.2  De existir el tag debe ser numerico, mayor a cero y como máximo tenga 2 decimales.
					De no cumplir generar código de error 2523 - GrossWeightMeasure – El dato ingresado no cumple con el formato establecido. -->
                    <xsl:if test="./cbc:GrossWeightMeasure &lt;= 0 or not(regexp:match(./cbc:GrossWeightMeasure,'^[0-9]{1,12}(\.[0-9]{1,2})?$'))">
                        <xsl:call-template name="addWarning"> <xsl:with-param name="warningCode" select="'2523'"/> <xsl:with-param name="warningMessage" select="'Expr Regular Factura (codigo: 2523)'"/></xsl:call-template>
                    </xsl:if>
                </xsl:if>
            </xsl:if>
        </xsl:for-each>
        <!-- js _ RF07 _ fin-->
        <!-- Ini: Validacion de la Guia de Remision Embebida -->
        <!-- actualizado 12/05/2014 inicio -->
        <!-- Fin: Validacion de la Guia de Remision Embebida -->
        <!-- actualizado 27/01/2014 inicio -->
        <xsl:if test="($sacAdditionalInformation/sac:AdditionalProperty/cbc:ID=1002
			and cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID=1000)
			and cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cbc:TaxExemptionReasonCode[text()='10' or text()='20' or text()='30' or text()='40']">
            <xsl:call-template name="addWarning"> <xsl:with-param name="warningCode" select="'4025'"/> <xsl:with-param name="warningMessage" select="'warning 4025'"/></xsl:call-template>
        </xsl:if>
        <!-- actualizado 27/01/2014 fin -->
        <!--<xsl:if test="($sacAdditionalInformation/sac:AdditionalProperty/cbc:ID
			= 1002) and ((cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cbc:TaxExemptionReasonCode=10)
			or (cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cbc:TaxExemptionReasonCode=20)
			or (cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cbc:TaxExemptionReasonCode=30)
			or (cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cbc:TaxExemptionReasonCode=40))">4025</xsl:if> -->
        <!-- actualizado 16/01/2014 fin -->



       <!-- Leyendas -->
        <xsl:if test="$sacAdditionalInformation/sac:AdditionalProperty/cbc:ID">
            <xsl:if test='not(regexp:match($sacAdditionalInformation/sac:AdditionalProperty/cbc:ID,"^[^\s]{4}$"))'>
                <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2366'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2366)'" /> </xsl:call-template>
            </xsl:if>
            <xsl:variable name="AdditionalPropertyId1000GreaterThan1" select="count($sacAdditionalInformation/sac:AdditionalProperty/cbc:ID[text()='1000'])>1"/>
            <xsl:variable name="AdditionalPropertyId1001GreaterThan1" select="count($sacAdditionalInformation/sac:AdditionalProperty/cbc:ID[text()='1001'])>1"/>
            <xsl:variable name="AdditionalPropertyId1002GreaterThan1" select="count($sacAdditionalInformation/sac:AdditionalProperty/cbc:ID[text()='1002'])>1"/>
            <xsl:variable name="AdditionalPropertyId2000GreaterThan1" select="count($sacAdditionalInformation/sac:AdditionalProperty/cbc:ID[text()='2000'])>1"/>
            <xsl:variable name="AdditionalPropertyId2001GreaterThan1" select="count($sacAdditionalInformation/sac:AdditionalProperty/cbc:ID[text()='2001'])>1"/>
            <xsl:variable name="AdditionalPropertyId2002GreaterThan1" select="count($sacAdditionalInformation/sac:AdditionalProperty/cbc:ID[text()='2002'])>1"/>
            <xsl:variable name="AdditionalPropertyId2003GreaterThan1" select="count($sacAdditionalInformation/sac:AdditionalProperty/cbc:ID[text()='2003'])>1"/>
            <xsl:if test="$AdditionalPropertyId1000GreaterThan1 or $AdditionalPropertyId1001GreaterThan1 or $AdditionalPropertyId1002GreaterThan1 or $AdditionalPropertyId2000GreaterThan1 or $AdditionalPropertyId2001GreaterThan1 or $AdditionalPropertyId2002GreaterThan1 or $AdditionalPropertyId2003GreaterThan1">
                <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2407'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2407)'" /> </xsl:call-template>
            </xsl:if>
        </xsl:if>


        <xsl:if test="$sacAdditionalInformation/sac:AdditionalProperty/cbc:Value">
            <xsl:if test='not(regexp:match($sacAdditionalInformation/sac:AdditionalProperty/cbc:Value,"^(?!\s*$).{1,100}"))'>
                <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2066'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2066)'" /> </xsl:call-template>
            </xsl:if>
        </xsl:if>
        <!-- Se incluye bloque en un for-each como en Validador Java - Inicio -->
        <xsl:for-each select="$additionalMonetaryTotal">
            <xsl:choose>
                <xsl:when test="not(string(./cbc:ID))">
                    <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2046'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2046)'" /> </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:variable name="respParametro">
                        <xsl:call-template name="parametro741">
                            <xsl:with-param name="codigo" select="./cbc:ID"/>
                        </xsl:call-template>
                    </xsl:variable>
                    <xsl:choose>
                        <xsl:when test='gemfunc:is-blank($respParametro)'>
                            <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2045'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2045)'" /> </xsl:call-template>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:if test="$sacSUNATTransactionID[text() = '04'] and (./cbc:ID[text() = '1001']) and (./cbc:PayableAmount[text()&lt;=0])">
                                <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2502'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2502)'" /> </xsl:call-template>
                            </xsl:if>
                            <xsl:if test="(./cbc:ID[text() = '2005']) and (not(./cbc:PayableAmount) or not(regexp:match(./cbc:PayableAmount,'^[0-9]{1,12}(\.[0-9]{1,2})?$')))">
                                <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2065'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2065)'" /> </xsl:call-template>
                            </xsl:if>
                        </xsl:otherwise>
                    </xsl:choose>
                    <!-- Se remplaza por parametro 741 -->
                    <!-- <xsl:if test='not(regexp:match($additionalMonetaryTotalID,"^[0-9]{4}$"))'>
						<xsl:call-template name="throwError">
							<xsl:with-param name="codigo" select="'2045'" />
						</xsl:call-template>
						<xsl:message terminate="yes" dp:priority="debug">
							<xsl:value-of select="'Error Expr Regular Factura (codigo: 2045)'" />
						</xsl:message>
					</xsl:if>
					-->
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
        <!-- Se incluye bloque en un for-each como en Validador Java - Fin -->
        <!-- Por lo menos deben de existir algunos los codigos -->
        <xsl:if test="not(($additionalMonetaryTotalID[text()='1001' or text()='1002' or text()='1003' or text()='1004' or text()='3001']))">
            <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2047'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2047)'" /> </xsl:call-template>
        </xsl:if>
        <xsl:if test="(count($additionalMonetaryTotalID[text()='1001'])>1)">
            <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2349'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2349)'" /> </xsl:call-template>
        </xsl:if>
        <xsl:if test="(count($additionalMonetaryTotalID[text()='1002'])>1)">
            <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2350'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2350)'" /> </xsl:call-template>
        </xsl:if>
        <xsl:if test="(count($additionalMonetaryTotalID[text()='1003'])>1)">
            <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2351'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2351)'" /> </xsl:call-template>
        </xsl:if>
        <!-- No deberian de haber duplicados -->
        <xsl:if test="(count($additionalMonetaryTotalID[text()='1001'])>1 or
				count($additionalMonetaryTotalID[text()='1002'])>1 or
				count($additionalMonetaryTotalID[text()='1003'])>1 or
				count($additionalMonetaryTotalID[text()='1004'])>1 or
				count($additionalMonetaryTotalID[text()='3001'])>1)">
            <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2406'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2406)'" /> </xsl:call-template>
        </xsl:if>
        <xsl:for-each select="$additionalMonetaryTotal">
            <xsl:choose>
                <xsl:when test="not(./cbc:PayableAmount)">
                    <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2044'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2044)'" /> </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:if test='not(regexp:match(./cbc:PayableAmount,"^[0-9]{1,12}(\.[0-9]{1,2})?$"))'>
                        <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2043'" /> <xsl:with-param name="errorMessage" select="'Error Expr Regular Factura (codigo: 2043)'" /> </xsl:call-template>
                    </xsl:if>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
        <xsl:copy-of select="."/>
    </xsl:template>

    <xsl:template name="comprobante_anticipado">

	</xsl:template>
    <!-- Template recursivo para obtener acumulador prepaidPayment-->
    <xsl:template name="getPrepaidPaymentAcum">
        <xsl:param name="Items"/>
        <xsl:variable name="Item1" select="$Items[1]"/>
        <xsl:variable name="RemainingItems" select="$Items[position() &gt; 1]"/>
        <xsl:variable name="acumulador" select="$Item1/cbc:PaidAmount"/>
        <xsl:choose>
            <xsl:when test="$RemainingItems">
                <xsl:if test="$Item1/cbc:PaidAmount and (regexp:match($Item1/cbc:PaidAmount,'^[0-9]{1,12}(\.[0-9]{1,2})?$') and $Item1/cbc:PaidAmount &gt; 0 )">
                    <xsl:variable name="subAcum">
                        <xsl:call-template name="getPrepaidPaymentAcum">
                            <xsl:with-param name="Items" select="$RemainingItems"/>
                        </xsl:call-template>
                    </xsl:variable>
                    <xsl:value-of select="$acumulador + $subAcum"/>
                </xsl:if>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$acumulador"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!-- Template para busqueda de parametro 741 -->
    <xsl:template name="parametro741">
        <xsl:param name="codigo"/>
        <xsl:variable name="descripcionParam" select="document('local:///commons/cpe/catalogo/Catalogo741.xml')"/>
        <xsl:value-of select="$descripcionParam/catalogo741/item[@numero=$codigo]"/>
    </xsl:template>
    <func:function name="gemfunc:is-blank">
        <xsl:param name="data" select="''"/>
        <func:result select="regexp:match($data,'^[\s]*$')"/>
    </func:function>

</xsl:stylesheet>
