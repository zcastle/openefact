<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:regexp="http://exslt.org/regular-expressions"
	xmlns:dyn="http://exslt.org/dynamic"
	xmlns:gemfunc="http://www.sunat.gob.pe/gem/functions"
	xmlns:date="http://exslt.org/dates-and-times"
	xmlns:func="http://exslt.org/functions"
	xmlns:dp="http://www.datapower.com/extensions"
	extension-element-prefixes="dp" exclude-result-prefixes="dp dyn regexp date func" version="1.0">
	<!-- xsl:include href="../../../commons/error/error_utils.xsl" dp:ignore-multiple="yes" /-->
	<xsl:include href="error_utils.xsl" dp:ignore-multiple="yes" />


	<!-- Template que sirve para validar si un nodo existe y si existe valida que se cumpla la expresion regular -->

	<xsl:template name="existAndRegexpValidateElement">
		<xsl:param name="errorCodeNotExist" />
		<xsl:param name="errorCodeValidate" />
		<xsl:param name="node" />
		<xsl:param name="regexp" />
		<xsl:param name="isError" select="true()"/>
		<xsl:param name="descripcion" select="'Error Expr Regular'"/>

		<xsl:choose>
			<xsl:when test="not(string($node))">
				<xsl:choose>
					<xsl:when test="$isError">
						<xsl:call-template name="rejectCall">
							<xsl:with-param name="errorCode" select="$errorCodeNotExist" />
							<xsl:with-param name="errorMessage" select="concat($descripcion,': ', $errorCodeNotExist,' (nodo: &quot;',name($node/parent::*),'/', name($node), '&quot; valor: &quot;', $node, '&quot;)')" />
						</xsl:call-template>
					</xsl:when>
					<xsl:otherwise>
						<xsl:call-template name="addWarning">
							<xsl:with-param name="warningCode" select="$errorCodeNotExist" />
							<xsl:with-param name="warningMessage" select="concat($descripcion,': ', $errorCodeNotExist,' (nodo: &quot;',name($node/parent::*),'/', name($node), '&quot; valor: &quot;', $node, '&quot;)')" />
						</xsl:call-template>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<xsl:if test='not(regexp:match(string($node),$regexp))'>
					<xsl:choose>
						<xsl:when test="$isError">
							<xsl:call-template name="rejectCall">
								<xsl:with-param name="errorCode" select="$errorCodeValidate" />
								<xsl:with-param name="errorMessage" select="concat($descripcion,': ', $errorCodeValidate,' (nodo: &quot;',name($node/parent::*),'/', name($node), '&quot; valor: &quot;', $node, '&quot;)')" />
							</xsl:call-template>
						</xsl:when>
						<xsl:otherwise>

							<xsl:call-template name="addWarning">
								<xsl:with-param name="warningCode" select="$errorCodeValidate" />
								<xsl:with-param name="warningMessage" select="concat($descripcion,': ', $errorCodeValidate,' (nodo: &quot;',name($node/parent::*),'/', name($node), '&quot; valor: &quot;', $node, '&quot;)')" />
							</xsl:call-template>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:if>
			</xsl:otherwise>
		</xsl:choose>


	</xsl:template>


	<!-- Template que sirve para validar un nodo y si el nodo existe, valida que se cumpla la expresion regular, si el nodo no existe no hace nada -->
    <!-- Se debe de usar para elementos opcionales -->

	<xsl:template name="regexpValidateElementIfExist">
		<xsl:param name="errorCodeValidate"/>
		<xsl:param name="node"/>
		<xsl:param name="regexp"/>
		<xsl:param name="isError" select="true()"/>
		<xsl:param name="descripcion" select="'Error Expr Regular'"/>

		<xsl:if test="count($node) &gt;= 1 and not(regexp:match($node,$regexp))">

			<xsl:choose>
				<xsl:when test="$isError">
					<xsl:call-template name="rejectCall">
						<xsl:with-param name="errorCode" select="$errorCodeValidate"/>
						<xsl:with-param name="errorMessage" select="concat($descripcion,': ', $errorCodeValidate,' (nodo: &quot;',name($node/parent::*),'/', name($node), '&quot; valor: &quot;', $node, '&quot;)')" />
					</xsl:call-template>
				</xsl:when>
				<xsl:otherwise>
						<xsl:call-template name="addWarning">
							<xsl:with-param name="warningCode" select="$errorCodeValidate" />
							<xsl:with-param name="warningMessage" select="concat($descripcion,': ', $errorCodeValidate,' (nodo: &quot;',name($node/parent::*),'/', name($node), '&quot; valor: &quot;', $node, '&quot;)')" />
						</xsl:call-template>
				</xsl:otherwise>
			</xsl:choose>

		</xsl:if>
	</xsl:template>


	<!-- Template que sirve para validar la existencia del valor de un tag dentro de un catalogo -->

	<xsl:template name="findElementInCatalog">
		<xsl:param name="errorCodeValidate" />
		<xsl:param name="idCatalogo" />
		<xsl:param name="catalogo" />

		<xsl:variable name="url_catalogo" select="concat('local:///commons/cpe/catalogo/cat_',$catalogo,'.xml')"/>

		<xsl:if test='count($idCatalogo) &gt;= 1 and count(document($url_catalogo)/l/c[@id=$idCatalogo]) &lt; 1 '>

			<xsl:call-template name="rejectCall">
				<xsl:with-param name="errorCode" select="$errorCodeValidate" />
				<xsl:with-param name="errorMessage" select="concat('Valor no se encuentra en el catalogo: ',$catalogo,' (nodo: &quot;',name($idCatalogo/parent::*),'/', name($idCatalogo), '&quot; valor: &quot;', $idCatalogo, '&quot;)')" />
			</xsl:call-template>

		</xsl:if>
	</xsl:template>

	<!-- Template que sirve para validar la existencia del valor de un tag dentro de un catalogo -->

	<xsl:template name="findElementInCatalogProperty">
		<xsl:param name="errorCodeValidate" />
		<xsl:param name="idCatalogo" />
		<xsl:param name="catalogo" />
		<xsl:param name="propiedad" />
		<xsl:param name="valorPropiedad" />

		<xsl:variable name="url_catalogo" select="concat('local:///commons/cpe/catalogo/cat_',$catalogo,'.xml')"/>

		<xsl:variable name="vCondition" select="concat('@id=',$idCatalogo,' and @', $propiedad, '=', $valorPropiedad)" />
		<xsl:variable name="apos">'</xsl:variable>
		<xsl:variable name="dynEval" select="concat('document(',$apos,$url_catalogo,$apos,')/l/c[', $vCondition, ']')" />

		<xsl:variable name="prueba" select="document($url_catalogo)/l/c[@id=01 and @tasa=2]" />

		<!-- xsl:if test="count(document('local:///commons/cpe/catalogo/cat_22.xml')/l/c[@id=$idCatalogo and @tasa=$valorPropiedad]) &lt; 1 " -->
		<xsl:if test="count(dyn:evaluate($dynEval)) &lt; 1 ">
			<xsl:call-template name="rejectCall">
				<xsl:with-param name="errorCode" select="$errorCodeValidate" />
				<xsl:with-param name="errorMessage" select="concat('condicion:',dyn:evaluate($dynEval),' Valor no se encuentra en el catalogo: ',$catalogo,', ID: ', $idCatalogo, '  (nodo: &quot;',name($node/parent::*),'/', name($idCatalogo), '&quot; propiedad ',$propiedad,': &quot;', $valorPropiedad, '&quot;)')" />
			</xsl:call-template>

		</xsl:if>
	</xsl:template>

	<!-- INI PAS20165E210300216 wsandovalh Template para obtener el valor de un atributo de un tag dentro de un catalogo -->
	<xsl:template name="getValueInCatalogProperty">
		<xsl:param name="idCatalogo" />
		<xsl:param name="catalogo" />
		<xsl:param name="propiedad" />

		<xsl:variable name="url_catalogo" select="concat('local:///commons/cpe/catalogo/cat_',$catalogo,'.xml')"/>
		<xsl:variable name="apos">'</xsl:variable>

		<xsl:variable name="dynEval" select="concat('document(',$apos,$url_catalogo,$apos,')/l/c[@id=', $idCatalogo, ']/@', $propiedad)" />

		<xsl:value-of select="dyn:evaluate($dynEval)" />

	</xsl:template>
	<!-- FIN PAS20165E210300216 wsandovalh Template para obtener el valor de un atributo de un tag dentro de un catalogo -->


	<!-- Template que sirve para verificar la expresion, si es verdadera lanza el error -->

	<xsl:template name="isTrueExpresion">
		<xsl:param name="errorCodeValidate" />
		<xsl:param name="node" />
		<xsl:param name="expresion" />
		<xsl:param name="isError" select="true()"/>
		<xsl:param name="descripcion" select="'Error '"/>

		<xsl:if test="$expresion = true()">

			<xsl:choose>
				<xsl:when test="$isError">
					<xsl:call-template name="rejectCall">
						<xsl:with-param name="errorCode" select="$errorCodeValidate" />
						<xsl:with-param name="errorMessage" select="concat($descripcion,': ', $errorCodeValidate,' (nodo: &quot;',name($node/parent::*),'/', name($node), '&quot; valor: &quot;', $node, '&quot;)')" />
					</xsl:call-template>
				</xsl:when>
				<xsl:otherwise>

					<xsl:call-template name="addWarning">
						<xsl:with-param name="warningCode" select="$errorCodeValidate" />
						<xsl:with-param name="warningMessage" select="concat($descripcion,': ', $errorCodeValidate,' (nodo: &quot;',name($node/parent::*),'/', name($node), '&quot; valor: &quot;', $node, '&quot;)')" />
					</xsl:call-template>
				</xsl:otherwise>
			</xsl:choose>

		</xsl:if>


	</xsl:template>

	<!-- Verifica si un contribuyente esta afiliado a otro (Ose o a un PSE) -->
	<xsl:template name="verifyAfiliacion">

		<xsl:param name="urlService"/>
		<xsl:param name="errorCode"/>
		<xsl:param name="errorMessage"/>

		<xsl:variable name="resp">
			<dp:url-open target="{$urlService}" response="responsecode-binary" http-method="get" timeout="300"/>
		</xsl:variable>

		<!--
		<xsl:message terminate="no" dp:category="cpe" dp:priority="warn">

			<xsl:copy-of select="$resp"></xsl:copy-of>

		</xsl:message>
		 -->

		<xsl:if test="string($resp/result/responsecode) != '200'">
			<xsl:call-template name="rejectCall">
            	<xsl:with-param name="errorCode" select="'200'" />
                <xsl:with-param name="errorMessage" select="concat('El servicio: ',$urlService, ' no esta disponible')" />
            </xsl:call-template>
		</xsl:if>

		<xsl:if test="$resp/result/headers/header[@name='ErrorCode']/text() != '200'">
        	<xsl:call-template name="rejectCall">
            	<xsl:with-param name="errorCode" select="$errorCode" />
                <xsl:with-param name="errorMessage" select="$errorMessage" />
            </xsl:call-template>
		</xsl:if>

	</xsl:template>

	<!-- verifca si un certificado le pertenece a un contribuyente:
	datos de entrada ruc mas numero de serie del certificado
	fecha en que fue firmado el comprobante
	retorna codigo de error y certificado validado
	-->

    <xsl:template name="validateCertContribuyente">
        <xsl:param name="rucCertSerialExaDecimal" />
        <xsl:param name="issueDate" />

        <xsl:variable name="certificates" select="document('local:///sistemagem/catalogos/certificados.xml')"/>
        <xsl:variable name="certificate" select="$certificates/l/c[@id=$rucCertSerialExaDecimal]"/>

		<xsl:variable name="errorCode" >

	        <xsl:choose>
	            <xsl:when test="$certificate">
	                <xsl:choose>
	                    <xsl:when test="$certificate/r =1 ">2328</xsl:when>
	                    <xsl:when test="$certificate/b =1 ">2326</xsl:when>
	                    <xsl:when test="(date:seconds(date:difference($issuedate,$certificate/f)) &lt; 0)">
							2327
	                    </xsl:when>
	                    <xsl:otherwise>0</xsl:otherwise>
	                </xsl:choose>
	            </xsl:when>
	            <xsl:otherwise>2325</xsl:otherwise>
	        </xsl:choose>
	    </xsl:variable>

	    <xsl:if test="$errorCode != 0">
            <xsl:call-template name="rejectCall">
				<xsl:with-param name="errorCode" select="$errorCode" />
				<xsl:with-param name="errorMessage" select="concat('Validation Cert Serial error: ', $errorCode ,' ruccertserial: ',$rucCertSerialExaDecimal,' issueDate: ', $issueDate)" />
			</xsl:call-template>
        </xsl:if>

    </xsl:template>

	<!-- obtenemos el numero de serie del certificado en base64 -->
	<xsl:template name="getCertificateSerialNumber">

		<xsl:param name="base64cert" />

        <!-- get the serial number of certificate -->
        <xsl:variable name="serialNumber">
            <xsl:value-of select="dp:get-cert-serial(concat('cert:',$base64cert))" />
        </xsl:variable>

		<xsl:variable name="lowercase" select="'abcdefghijklmnopqrstuvwxyz'" />
		<xsl:variable name="uppercase" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ'" />

		<xsl:value-of  select="translate(dp:radix-convert($serialNumber, 10, 16),$uppercase,$lowercase)" />

	</xsl:template>

	<func:function name="gemfunc:is-blank">
		<xsl:param name="data" select="''"/>
		<func:result select="regexp:match($data,'^[\s]*$')"/>
	</func:function>


</xsl:stylesheet>
