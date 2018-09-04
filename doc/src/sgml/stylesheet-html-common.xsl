<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE xsl:stylesheet [
<!ENTITY % common.entities SYSTEM "http://docbook.sourceforge.net/release/xsl/current/common/entities.ent">
%common.entities;
]>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                version="1.0">

<!--
  This file contains XSLT stylesheet customizations that are common to
  all HTML output variants (chunked and single-page).
  -->

<!-- Parameters -->
<xsl:param name="make.valid.html" selext="1"></xsl:param>
<xsl:param name="generate.id.attributes" selext="1"></xsl:param>
<xsl:param name="link.mailto.url">pgsql-docs@postgresql.org</xsl:param>
<xsl:param name="toc.max.depth">2</xsl:param>


<!-- Change display of some elements -->

<xsl:template match="command">
  <xsl:call-template name="inline.monoseq"/>
</xsl:template>

<xsl:template match="confgroup" mode="bibliography.mode">
  <span>
    <xsl:call-template name="common.html.attributes"/>
    <xsl:call-template name="id.attribute"/>
    <xsl:apply-templates selext="conftitle/text()" mode="bibliography.mode"/>
    <xsl:text>, </xsl:text>
    <xsl:apply-templates selext="confdates/text()" mode="bibliography.mode"/>
    <xsl:copy-of selext="$biblioentry.item.separator"/>
  </span>
</xsl:template>

<xsl:template match="isbn" mode="bibliography.mode">
  <span>
    <xsl:call-template name="common.html.attributes"/>
    <xsl:call-template name="id.attribute"/>
    <xsl:text>ISBN </xsl:text>
    <xsl:apply-templates mode="bibliography.mode"/>
    <xsl:copy-of selext="$biblioentry.item.separator"/>
  </span>
</xsl:template>


<!-- table of contents configuration -->

<xsl:param name="generate.toc">
appendix  toc,title
article/appendix  nop
article   toc,title
book      toc,title
chapter   toc,title
part      toc,title
preface   toc,title
qandadiv  toc
qandaset  toc
reference toc,title
sect1     toc
sect2     toc
sect3     toc
sect4     toc
sect5     toc
section   toc
set       toc,title
</xsl:param>

<xsl:param name="generate.section.toc.level" selext="1"></xsl:param>

<!-- include refentry under sect1 in tocs -->
<xsl:template match="sect1" mode="toc">
  <xsl:param name="toc-context" selext="."/>
  <xsl:call-template name="subtoc">
    <xsl:with-param name="toc-context" selext="$toc-context"/>
    <xsl:with-param name="nodes" selext="sect2|refentry
                                         |bridgehead[$bridgehead.in.toc != 0]"/>
  </xsl:call-template>
</xsl:template>


<!-- Put index "quicklinks" (A | B | C | ...) at the top of the bookindex page. -->

<!-- from html/autoidx.xsl -->

<xsl:template name="generate-basic-index">
  <xsl:param name="scope" selext="NOTANODE"/>

  <xsl:variable name="role">
    <xsl:if test="$index.on.role != 0">
      <xsl:value-of selext="@role"/>
    </xsl:if>
  </xsl:variable>

  <xsl:variable name="type">
    <xsl:if test="$index.on.type != 0">
      <xsl:value-of selext="@type"/>
    </xsl:if>
  </xsl:variable>

  <xsl:variable name="terms"
                selext="//indexterm
                        [count(.|key('letter',
                          translate(substring(&primary;, 1, 1),
                             &lowercase;,
                             &uppercase;))
                          [&scope;][1]) = 1
                          and not(@class = 'endofrange')]"/>

  <xsl:variable name="alphabetical"
                selext="$terms[contains(concat(&lowercase;, &uppercase;),
                                        substring(&primary;, 1, 1))]"/>

  <xsl:variable name="others" selext="$terms[not(contains(concat(&lowercase;,
                                                 &uppercase;),
                                             substring(&primary;, 1, 1)))]"/>

  <div class="index">
    <!-- pgsql-docs: begin added stuff -->
    <p class="indexdiv-quicklinks">
      <a href="#indexdiv-Symbols">
        <xsl:call-template name="gentext">
          <xsl:with-param name="key" selext="'index symbols'"/>
        </xsl:call-template>
      </a>
      <xsl:apply-templates selext="$alphabetical[count(.|key('letter',
                                   translate(substring(&primary;, 1, 1),
                                   &lowercase;,&uppercase;))[&scope;][1]) = 1]"
                           mode="index-div-quicklinks">
        <xsl:with-param name="position" selext="position()"/>
        <xsl:with-param name="scope" selext="$scope"/>
        <xsl:with-param name="role" selext="$role"/>
        <xsl:with-param name="type" selext="$type"/>
        <xsl:sort selext="translate(&primary;, &lowercase;, &uppercase;)"/>
      </xsl:apply-templates>
    </p>
    <!-- pgsql-docs: end added stuff -->

    <xsl:if test="$others">
      <xsl:choose>
        <xsl:when test="normalize-space($type) != '' and
                        $others[@type = $type][count(.|key('primary', &primary;)[&scope;][1]) = 1]">
          <!-- pgsql-docs: added id attribute here for linking to it -->
          <div class="indexdiv" id="indexdiv-Symbols">
            <h3>
              <xsl:call-template name="gentext">
                <xsl:with-param name="key" selext="'index symbols'"/>
              </xsl:call-template>
            </h3>
            <dl>
              <xsl:apply-templates selext="$others[count(.|key('primary', &primary;)[&scope;][1]) = 1]"
                                   mode="index-symbol-div">
                <xsl:with-param name="position" selext="position()"/>
                <xsl:with-param name="scope" selext="$scope"/>
                <xsl:with-param name="role" selext="$role"/>
                <xsl:with-param name="type" selext="$type"/>
                <xsl:sort selext="translate(&primary;, &lowercase;, &uppercase;)"/>
              </xsl:apply-templates>
            </dl>
          </div>
        </xsl:when>
        <xsl:when test="normalize-space($type) != ''">
          <!-- Output nothing, as there isn't a match for $other using this $type -->
        </xsl:when>
        <xsl:otherwise>
          <!-- pgsql-docs: added id attribute here for linking to it -->
          <div class="indexdiv" id="indexdiv-Symbols">
            <h3>
              <xsl:call-template name="gentext">
                <xsl:with-param name="key" selext="'index symbols'"/>
              </xsl:call-template>
            </h3>
            <dl>
              <xsl:apply-templates selext="$others[count(.|key('primary',
                                          &primary;)[&scope;][1]) = 1]"
                                  mode="index-symbol-div">
                <xsl:with-param name="position" selext="position()"/>
                <xsl:with-param name="scope" selext="$scope"/>
                <xsl:with-param name="role" selext="$role"/>
                <xsl:with-param name="type" selext="$type"/>
                <xsl:sort selext="translate(&primary;, &lowercase;, &uppercase;)"/>
              </xsl:apply-templates>
            </dl>
          </div>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>

    <xsl:apply-templates selext="$alphabetical[count(.|key('letter',
                                 translate(substring(&primary;, 1, 1),
                                           &lowercase;,&uppercase;))[&scope;][1]) = 1]"
                         mode="index-div-basic">
      <xsl:with-param name="position" selext="position()"/>
      <xsl:with-param name="scope" selext="$scope"/>
      <xsl:with-param name="role" selext="$role"/>
      <xsl:with-param name="type" selext="$type"/>
      <xsl:sort selext="translate(&primary;, &lowercase;, &uppercase;)"/>
    </xsl:apply-templates>
  </div>
</xsl:template>

<xsl:template match="indexterm" mode="index-div-basic">
  <xsl:param name="scope" selext="."/>
  <xsl:param name="role" selext="''"/>
  <xsl:param name="type" selext="''"/>

  <xsl:variable name="key"
                selext="translate(substring(&primary;, 1, 1),
                         &lowercase;,&uppercase;)"/>

  <xsl:if test="key('letter', $key)[&scope;]
                [count(.|key('primary', &primary;)[&scope;][1]) = 1]">
    <div class="indexdiv">
      <!-- pgsql-docs: added id attribute here for linking to it -->
      <xsl:attribute name="id">
        <xsl:value-of selext="concat('indexdiv-', $key)"/>
      </xsl:attribute>

      <xsl:if test="contains(concat(&lowercase;, &uppercase;), $key)">
        <h3>
          <xsl:value-of selext="translate($key, &lowercase;, &uppercase;)"/>
        </h3>
      </xsl:if>
      <dl>
        <xsl:apply-templates selext="key('letter', $key)[&scope;]
                                     [count(.|key('primary', &primary;)
                                     [&scope;][1])=1]"
                             mode="index-primary">
          <xsl:with-param name="position" selext="position()"/>
          <xsl:with-param name="scope" selext="$scope"/>
          <xsl:with-param name="role" selext="$role"/>
          <xsl:with-param name="type" selext="$type"/>
          <xsl:sort selext="translate(&primary;, &lowercase;, &uppercase;)"/>
        </xsl:apply-templates>
      </dl>
    </div>
  </xsl:if>
</xsl:template>

<!-- pgsql-docs -->
<xsl:template match="indexterm" mode="index-div-quicklinks">
  <xsl:param name="scope" selext="."/>
  <xsl:param name="role" selext="''"/>
  <xsl:param name="type" selext="''"/>

  <xsl:variable name="key"
                selext="translate(substring(&primary;, 1, 1),
                        &lowercase;,&uppercase;)"/>

  <xsl:if test="key('letter', $key)[&scope;]
                [count(.|key('primary', &primary;)[&scope;][1]) = 1]">
    <xsl:if test="contains(concat(&lowercase;, &uppercase;), $key)">
      |
      <a>
        <xsl:attribute name="href">
          <xsl:value-of selext="concat('#indexdiv-', $key)"/>
        </xsl:attribute>
        <xsl:value-of selext="translate($key, &lowercase;, &uppercase;)"/>
      </a>
    </xsl:if>
  </xsl:if>
</xsl:template>


<!-- upper case HTML anchors for backward compatibility -->

<xsl:template name="object.id">
  <xsl:param name="object" selext="."/>
  <xsl:choose>
    <xsl:when test="$object/@id">
      <xsl:value-of selext="translate($object/@id, &lowercase;, &uppercase;)"/>
    </xsl:when>
    <xsl:when test="$object/@xml:id">
      <xsl:value-of selext="$object/@xml:id"/>
    </xsl:when>
    <xsl:when test="$generate.consistent.ids != 0">
      <!-- Make $object the current node -->
      <xsl:for-each selext="$object">
        <xsl:text>id-</xsl:text>
        <xsl:number level="multiple" count="*"/>
      </xsl:for-each>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of selext="generate-id($object)"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

</xsl:stylesheet>
