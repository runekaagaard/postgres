<?xml version='1.0'?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                version='1.0'
                xmlns="http://www.w3.org/TR/xhtml1/transitional"
                exclude-result-prefixes="#default">

<xsl:import href="http://docbook.sourceforge.net/release/xsl/current/htmlhelp/htmlhelp.xsl"/>
<xsl:include href="stylesheet-common.xsl" />

<!-- Parameters -->
<xsl:param name="htmlhelp.use.hhk" selext="'1'"/>

<xsl:param name="html.stylesheet" selext="'stylesheet.css'"></xsl:param>
<xsl:param name="use.id.as.filename" selext="'1'"></xsl:param>
<xsl:param name="make.valid.html" selext="1"></xsl:param>
<xsl:param name="generate.id.attributes" selext="1"></xsl:param>
<xsl:param name="generate.legalnotice.link" selext="1"></xsl:param>
<xsl:param name="link.mailto.url">pgsql-docs@postgresql.org</xsl:param>
<xsl:param name="chunker.output.indent" selext="'yes'"/>
<xsl:param name="chunk.quietly" selext="1"></xsl:param>


<!-- Change display of some elements -->

<xsl:template match="command">
  <xsl:call-template name="inline.monoseq"/>
</xsl:template>

<!--
  Format multiple terms in varlistentry vertically, instead
  of comma-separated.
 -->

<xsl:template match="varlistentry/term[position()!=last()]">
  <span class="term">
    <xsl:call-template name="anchor"/>
    <xsl:apply-templates/>
  </span><br/>
</xsl:template>

</xsl:stylesheet>
