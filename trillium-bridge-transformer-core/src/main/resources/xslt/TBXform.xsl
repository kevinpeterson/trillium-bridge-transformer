<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:v3="urn:hl7-org:v3"
    xmlns:tbx="http://trilliumbridge.org/xform" 
    exclude-result-prefixes="xs v3 tbx mapVersion core mapServices codeSystem"
    version="2.0" 
    xmlns:mapVersion="http://www.omg.org/spec/CTS2/1.1/MapVersion"
    xmlns:mapServices="http://www.omg.org/spec/CTS2/1.1/MapEntryServices"
    xmlns:codeSystem="http://schema.omg.org/spec/CTS2/1.0/CodeSystem"
    xmlns:core="http://www.omg.org/spec/CTS2/1.1/Core" xpath-default-namespace="urn:hl7-org:v3">


    <xsl:variable name="maps">
        <xsl:copy-of select="doc('FP7-SA610756-D3.1.xml')"/>
    </xsl:variable>

    <xsl:variable name="valuesets">
        <xsl:copy-of select="doc('ValueSetMaps.xml')"/>
    </xsl:variable>

    <xsl:param name="from">epSOS</xsl:param>
    <xsl:param name="to">CCD</xsl:param>
    <xsl:param name="tolanguage">en</xsl:param>
    
    <xsl:variable name="apos">'</xsl:variable>
    <xsl:variable name="quot">"</xsl:variable>
    
    <!-- Code system translator -->
    <xsl:function name="tbx:uriToEntityReference" as="element(tbx:conceptReference)">
        <xsl:param name="uri"/>
        <xsl:variable name="code" select="replace($uri, '.*/', '')"/>
        <xsl:variable name="codeSystemUri" select="replace($uri, '/.*','')"/>
        <xsl:variable name="codeSystemEntry" 
            select="document('http://rd.phast.fr/REST/sts_rest_beta_2/0004/codesystems')//codeSystem:entry[@about=$codeSystemUri]"/>
        <tbx:conceptReference uri="{$uri}" xmlns="http://www.omg.org/spec/CTS2/1.1/Core">
            <core:namespace><xsl:value-of select="$codeSystemEntry/@codeSystemName"/></core:namespace>
            <core:name><xsl:value-of select="$code"/></core:name>
        </tbx:conceptReference>
    </xsl:function>
    

    <!-- Terminology access routines
        
        getMapEntry takes a code system and code and value set map entry, which provides the 
        name of the map to use in the transformation.
        
        The map entry provides -->

    <xsl:template name="getMapEntry">
        <xsl:param name="path"/>
        <xsl:param name="language"/>

        <xsl:param name="vsmapentry"/>
        <xsl:param name="code"/>
        <xsl:param name="codeSystem"/>

        <xsl:variable name="docroot">
            <xsl:value-of
                select="replace(replace($vsmapentry/tbx:uripattern, '\{code\}', $code), '\{codeSystem\}', $codeSystem)"/>
        </xsl:variable>

        <xsl:variable name="target">
            <xsl:choose>
                <xsl:when test="$vsmapentry/@entireMap='true'">
                    <xsl:copy-of
                        select="document($docroot)/mapVersion:MapEntryList/mapVersion:entry/mapVersion:entry[mapVersion:mapFrom/core:namespace=$codeSystem and mapVersion:mapFrom/core:name=$code]/mapVersion:mapSet/mapVersion:mapTarget/mapVersion:mapTo"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:copy-of
                        select="document($docroot)/mapServices:MapTargetListMsg/mapServices:mapTargetList/mapServices:entry/mapVersion:mapTo"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:variable name="conceptReference" select="tbx:uriToEntityReference($target/mapVersion:mapTo/@uri)"/>
        

        <code codeSystem="{substring-after(substring-before($conceptReference/@uri,'/'), 'urn:oid:')}" codeSystemName="{$conceptReference/core:namespace}"
            code="{$target/mapVersion:mapTo/core:name}" displayName="{$target/mapVersion:mapTo/core:designation}"
            xmlns="urn:hl7-org:v3">
            <translation>
                <xsl:apply-templates select="@* | node()">
                    <xsl:with-param name="path" select="$path"/>
                    <xsl:with-param name="language" select="$language"/>
                </xsl:apply-templates>
            </translation>
        </code>
    </xsl:template>

    <xsl:template name="mapValueSet">
        <xsl:param name="path"/>
        <xsl:param name="language"/>
        <xsl:param name="context"/>
        <xsl:param name="args" select="current()"/>
        <xsl:for-each select="$context">
            <xsl:choose>
                <xsl:when test="$valuesets/tbx:valuesetmap/tbx:entry[@name=$args/@map]">
                    <xsl:call-template name="getMapEntry">
                        <xsl:with-param name="path" select="$path"/>
                        <xsl:with-param name="language" select="$language"/>
                        <xsl:with-param name="code" select="@code"/>
                        <xsl:with-param name="codeSystem" select="@codeSystemName"/>
                        <xsl:with-param name="vsmapentry"
                            select="$valuesets/tbx:valuesetmap/tbx:entry[@name=$args/@map]"/>
                    </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                    <code xmlns="urn:hl7-org.v3" displayName="MAP: {$args/@map} not found">
                        <translation>
                            <xsl:apply-templates select="@* | node()">
                                <xsl:with-param name="path" select="$path"/>
                                <xsl:with-param name="language" select="$language"/>
                            </xsl:apply-templates>
                        </translation>
                    </code>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:template>

    <xsl:template name="changeTemplateRoots">
        <xsl:param name="path"/>
        <xsl:param name="language"/>
        <xsl:param name="context"/>
        <xsl:param name="args" select="current()"/>
        <xsl:for-each select="$context">
            <xsl:choose>
                <xsl:when test="$args/tbx:entry[@fromid=current()/@root]">
                    <xsl:if test="$args/tbx:entry[@fromid=current()/@root]/@toid">
                        <templateId root="{$args/tbx:entry[@fromid=current()/@root]/@toid}"
                            xmlns="urn:hl7-org:v3"/>
                    </xsl:if>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:copy>
                        <xsl:apply-templates select="@*"/>
                    </xsl:copy>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:template>

    <xsl:template name="replaceCode" xmlns="urn:hl7-org:v3">
        <xsl:param name="path"/>
        <xsl:param name="language"/>
        <xsl:param name="context"/>
        <xsl:param name="args" select="current()"/>

        <xsl:for-each select="$context">
            <xsl:choose>
                <xsl:when test="$args/tbx:entry[tbx:fromcode/v3:code=current()]">
                    <xsl:if test="$args/tbx:entry[tbx:fromcode/v3:code=current()]/tbx:tocode">
                        <xsl:copy-of
                            select="$args/tbx:entry[tbx:fromcode/v3:code=current()]/tbx:tocode/v3:code"
                        />
                    </xsl:if>
                </xsl:when>
                <xsl:when test="not($args/tbx:entry/tbx:fromcode)">
                    <xsl:copy-of select="$args/tbx:entry/tbx:tocode/v3:code"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:copy>
                        <xsl:apply-templates select="node() | @*">
                            <xsl:with-param name="path" select="$path"/>
                            <xsl:with-param name="language" select="$language"/>
                        </xsl:apply-templates>
                    </xsl:copy>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:template>

    <xsl:template name="replaceValue" xmlns="urn:hl7-org:v3">
        <xsl:param name="path"/>
        <xsl:param name="language"/>
        <xsl:param name="context"/>
        <xsl:param name="args" select="current()"/>
        <!-- TODO: case 1 below does not work -->
        <xsl:for-each select="$context">
            <xsl:choose>
                <xsl:when test="$args/tbx:entry[tbx:fromValue/tbx:value=current()]">
                    <xsl:if test="$args/tbx:entry[tbx:toValue/v3:value=current()]/tbx:toValue">
                        <xsl:copy-of
                            select="$args/tbx:entry[tbx:fromValue/v3:value=current()]/tbx:toValue/v3:value"
                        />
                    </xsl:if>
                </xsl:when>
                <xsl:when test="not($args/tbx:entry/tbx:fromValue)">
                    <xsl:copy-of select="$args/tbx:entry/tbx:toValue/v3:value"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:copy>
                        <xsl:apply-templates select="node() | @*">
                            <xsl:with-param name="path" select="$path"/>
                            <xsl:with-param name="language" select="$language"/>
                        </xsl:apply-templates>
                    </xsl:copy>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:template>

    <xsl:template name="translateText" xmlns="urn:hl7-org:v3">
        <xsl:param name="path"/>
        <xsl:param name="language"/>
        <xsl:param name="context"/>
        <xsl:param name="args" select="current()"/>

        <!-- This is where we fill in a fancy translation service.
             The arguments to translateText could include the address of some web based translation -->
        <xsl:for-each select="$context">
            <text>
                <paragraph>Original Text</paragraph>
                <br/>
                <xsl:copy-of select="."/>
                <paragraph>Warning: this translation has been generated by a software component</paragraph>
                <br />
                <xsl:apply-templates mode="faketranslate"/>
                <br />
            </text>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="@* | node()" mode="faketranslate" xmlns="urn:hl7-org:v3">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:value-of select="replace(., '[a-zA-Z]', 't')"/>
            <xsl:apply-templates select="node()" mode="faketranslate"/>
        </xsl:copy>
    </xsl:template>


    <xsl:template name="newid">
        <xsl:param name="path"/>
        <xsl:param name="language"/>
        <xsl:param name="context"/>
        <xsl:for-each select="$context">
            <id xmlns="urn:hl7-org:v3" extension="{concat(@extension, '.1.1')}">
                <xsl:apply-templates select="@*[name() !='extension']"/>
            </id>
        </xsl:for-each>
    </xsl:template>

    <xsl:template name="translateTitle">
        <xsl:param name="path"/>
        <xsl:param name="language"/>
        <xsl:param name="context"/>

        <xsl:for-each select="$context">
            <xsl:variable name="transdoc"
                select="concat('../translation/',$language, 'to', $tolanguage, '.xml')"/>
            <xsl:variable name="translations" select="document($transdoc)/tbx:translations"/>
            <xsl:variable name="src" select="."/>
            <xsl:choose>
                <xsl:when test="$translations/tbx:entry[tbx:source=$src]">
                    <title xmlns="urn:hl7-org:v3">
                        <xsl:value-of select="$translations/tbx:entry[tbx:source=$src]/tbx:target"/>
                    </title>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:copy-of select="."/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="@*">
        <xsl:copy/>
    </xsl:template>

    <xsl:template match="//ClinicalDocument">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()">
                <xsl:with-param name="path" select="'/ClinicalDocument'"/>
                <xsl:with-param name="language" select="languageCode/@code"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template name="refmark">
         <xsl:choose>
             <xsl:when test="../templateId">
                 <xsl:value-of select="concat('[templateId/@root=', $quot, ../templateId[1]/@root, $quot, ']')"/>
             </xsl:when>
             <xsl:when test="../@typeCode">
                 <xsl:value-of select="concat('[@typeCode=', $quot, ../@typeCode, $quot, ']')"/>
             </xsl:when>
             <xsl:when test="../@classCode">
                 <xsl:value-of select="concat('[@typeCode=', $quot, ../@typeCode, $quot, ']')"/>
             </xsl:when>
             <xsl:otherwise/>
         </xsl:choose>
    </xsl:template>

    <xsl:template match="node()" xmlns="urn:hl7-org:v3">
        <xsl:param name="path"/>
        <xsl:param name="language"/>

        <xsl:variable name="rm">
            <xsl:call-template name="refmark"/>
        </xsl:variable>
        <xsl:variable name="loc" select="concat($path, $rm, '/', name())"/>
        <xsl:variable name="context" select="current()"/>
        <xsl:choose>
            <xsl:when test="$maps/tbx:map/tbx:entry[@from=$from and @to=$to and tbx:frompath=$loc]">
<!--                PATH: <xsl:value-of select="$loc"/>|-->
                <xsl:for-each
                    select="$maps/tbx:map/tbx:entry[@from=$from and @to=$to and tbx:frompath=$loc]/tbx:transformation">
                    <xsl:choose>
                        <xsl:when test="@name='changeTemplateRoots'">
                            <xsl:call-template name="changeTemplateRoots">
                                <xsl:with-param name="path" select="$loc"/>
                                <xsl:with-param name="language" select="$language"/>
                                <xsl:with-param name="context" select="$context"/>
                            </xsl:call-template>
                        </xsl:when>
                        <xsl:when test="@name='translateTitle'">
                            <xsl:call-template name="translateTitle">
                                <xsl:with-param name="path" select="$loc"/>
                                <xsl:with-param name="language" select="$language"/>
                                <xsl:with-param name="context" select="$context"/>
                            </xsl:call-template>
                        </xsl:when>
                        <xsl:when test="@name='newid'">
                            <xsl:call-template name="newid">
                                <xsl:with-param name="path" select="$loc"/>
                                <xsl:with-param name="language" select="$language"/>
                                <xsl:with-param name="context" select="$context"/>
                            </xsl:call-template>
                        </xsl:when>
                        <xsl:when test="@name='mapValueSet'">
                            <xsl:call-template name="mapValueSet">
                                <xsl:with-param name="path" select="$loc"/>
                                <xsl:with-param name="language" select="$language"/>
                                <xsl:with-param name="context" select="$context"/>
                            </xsl:call-template>
                        </xsl:when>
                        <xsl:when test="@name='replaceCode'">
                            <xsl:call-template name="replaceCode">
                                <xsl:with-param name="path" select="$loc"/>
                                <xsl:with-param name="language" select="$language"/>
                                <xsl:with-param name="context" select="$context"/>
                            </xsl:call-template>
                        </xsl:when>
                        <xsl:when test="@name='replaceValue'">
                            <xsl:call-template name="replaceValue">
                                <xsl:with-param name="path" select="$loc"/>
                                <xsl:with-param name="language" select="$language"/>
                                <xsl:with-param name="context" select="$context"/>
                            </xsl:call-template>
                        </xsl:when>
                        <xsl:when test="@name='translateText'">
                            <xsl:call-template name="translateText">
                                <xsl:with-param name="path" select="$loc"/>
                                <xsl:with-param name="language" select="$language"/>
                                <xsl:with-param name="context" select="$context"/>
                            </xsl:call-template>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:comment>UNMAPPED FUNCTION: <xsl:value-of select="@name"/></xsl:comment>
                            <xsl:call-template name="cr"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each>
            </xsl:when>
            <xsl:when test="name()='languageCode'">
                <languageCode code="{$tolanguage}"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy>
                    <xsl:apply-templates select="@* | node()">
                        <xsl:with-param name="path" select="$loc"/>
                        <xsl:with-param name="language" select="$language"/>
                    </xsl:apply-templates>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="cr">
        <xsl:value-of select="'&#xa;'"/>
    </xsl:template>


</xsl:stylesheet>
