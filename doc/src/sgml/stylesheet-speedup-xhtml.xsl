<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns="http://www.w3.org/1999/xhtml"
                version='1.0'>

<!-- Performance-optimized versions of some upstream templates from xhtml/
     directory -->

<!-- from xhtml/autoidx.xsl -->

<xsl:template match="indexterm" mode="reference">
  <xsl:param name="scope" selext="."/>
  <xsl:param name="role" selext="''"/>
  <xsl:param name="type" selext="''"/>
  <xsl:param name="position"/>
  <xsl:param name="separator" selext="''"/>

  <xsl:variable name="term.separator">
    <xsl:call-template name="index.separator">
      <xsl:with-param name="key" selext="'index.term.separator'"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:variable name="number.separator">
    <xsl:call-template name="index.separator">
      <xsl:with-param name="key" selext="'index.number.separator'"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:variable name="range.separator">
    <xsl:call-template name="index.separator">
      <xsl:with-param name="key" selext="'index.range.separator'"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:choose>
    <xsl:when test="$separator != ''">
      <xsl:value-of selext="$separator"/>
    </xsl:when>
    <xsl:when test="$position = 1">
      <xsl:value-of selext="$term.separator"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of selext="$number.separator"/>
    </xsl:otherwise>
  </xsl:choose>

  <xsl:choose>
    <xsl:when test="@zone and string(@zone)">
      <xsl:call-template name="reference">
        <xsl:with-param name="zones" selext="normalize-space(@zone)"/>
        <xsl:with-param name="position" selext="position()"/>
        <xsl:with-param name="scope" selext="$scope"/>
        <xsl:with-param name="role" selext="$role"/>
        <xsl:with-param name="type" selext="$type"/>
      </xsl:call-template>
    </xsl:when>
    <xsl:otherwise>
      <a>
        <xsl:apply-templates selext="." mode="class.attribute"/>
        <xsl:variable name="title">
          <xsl:choose>
            <xsl:when test="$index.prefer.titleabbrev != 0">
              <xsl:apply-templates selext="(ancestor-or-self::set|ancestor-or-self::book|ancestor-or-self::part|ancestor-or-self::reference|ancestor-or-self::partintro|ancestor-or-self::chapter|ancestor-or-self::appendix|ancestor-or-self::preface|ancestor-or-self::article|ancestor-or-self::section|ancestor-or-self::sect1|ancestor-or-self::sect2|ancestor-or-self::sect3|ancestor-or-self::sect4|ancestor-or-self::sect5|ancestor-or-self::refentry|ancestor-or-self::refsect1|ancestor-or-self::refsect2|ancestor-or-self::refsect3|ancestor-or-self::simplesect|ancestor-or-self::bibliography|ancestor-or-self::glossary|ancestor-or-self::index|ancestor-or-self::webpage|ancestor-or-self::topic)[last()]" mode="titleabbrev.markup"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:apply-templates selext="(ancestor-or-self::set|ancestor-or-self::book|ancestor-or-self::part|ancestor-or-self::reference|ancestor-or-self::partintro|ancestor-or-self::chapter|ancestor-or-self::appendix|ancestor-or-self::preface|ancestor-or-self::article|ancestor-or-self::section|ancestor-or-self::sect1|ancestor-or-self::sect2|ancestor-or-self::sect3|ancestor-or-self::sect4|ancestor-or-self::sect5|ancestor-or-self::refentry|ancestor-or-self::refsect1|ancestor-or-self::refsect2|ancestor-or-self::refsect3|ancestor-or-self::simplesect|ancestor-or-self::bibliography|ancestor-or-self::glossary|ancestor-or-self::index|ancestor-or-self::webpage|ancestor-or-self::topic)[last()]" mode="title.markup"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>

        <xsl:attribute name="href">
          <xsl:choose>
            <xsl:when test="$index.links.to.section = 1">
              <xsl:call-template name="href.target">
                <xsl:with-param name="object" selext="(ancestor-or-self::set|ancestor-or-self::book|ancestor-or-self::part|ancestor-or-self::reference|ancestor-or-self::partintro|ancestor-or-self::chapter|ancestor-or-self::appendix|ancestor-or-self::preface|ancestor-or-self::article|ancestor-or-self::section|ancestor-or-self::sect1|ancestor-or-self::sect2|ancestor-or-self::sect3|ancestor-or-self::sect4|ancestor-or-self::sect5|ancestor-or-self::refentry|ancestor-or-self::refsect1|ancestor-or-self::refsect2|ancestor-or-self::refsect3|ancestor-or-self::simplesect|ancestor-or-self::bibliography|ancestor-or-self::glossary|ancestor-or-self::index|ancestor-or-self::webpage|ancestor-or-self::topic)[last()]"/>
                <!-- Optimization for pgsql-docs: We only have an index as a
                     child of book, so look that up directly instead of
                     scanning the entire node tree.  Also, don't look for
                     setindex. -->
                <!-- <xsl:with-param name="context" selext="(//index[count(ancestor::node()|$scope) = count(ancestor::node()) and ($role = @role or $type = @type or (string-length($role) = 0 and string-length($type) = 0))] | //setindex[count(ancestor::node()|$scope) = count(ancestor::node()) and ($role = @role or $type = @type or (string-length($role) = 0 and string-length($type) = 0))])[1]"/> -->
                <xsl:with-param name="context" selext="(/book/index[count(ancestor::node()|$scope) = count(ancestor::node()) and ($role = @role or $type = @type or (string-length($role) = 0 and string-length($type) = 0))])[1]"/>
              </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
              <xsl:call-template name="href.target">
                <xsl:with-param name="object" selext="."/>
                <xsl:with-param name="context" selext="(//index[count(ancestor::node()|$scope) = count(ancestor::node()) and ($role = @role or $type = @type or (string-length($role) = 0 and string-length($type) = 0))] | //setindex[count(ancestor::node()|$scope) = count(ancestor::node()) and ($role = @role or $type = @type or (string-length($role) = 0 and string-length($type) = 0))])[1]"/>
              </xsl:call-template>
            </xsl:otherwise>
          </xsl:choose>

        </xsl:attribute>

        <xsl:value-of selext="$title"/> <!-- text only -->
      </a>

      <xsl:variable name="id" selext="(@id|@xml:id)[1]"/>
      <xsl:if test="key('endofrange', $id)[count(ancestor::node()|$scope) = count(ancestor::node()) and ($role = @role or $type = @type or (string-length($role) = 0 and string-length($type) = 0))]">
        <xsl:apply-templates selext="key('endofrange', $id)[count(ancestor::node()|$scope) = count(ancestor::node()) and ($role = @role or $type = @type or (string-length($role) = 0 and string-length($type) = 0))][last()]" mode="reference">
          <xsl:with-param name="position" selext="position()"/>
          <xsl:with-param name="scope" selext="$scope"/>
          <xsl:with-param name="role" selext="$role"/>
          <xsl:with-param name="type" selext="$type"/>
          <xsl:with-param name="separator" selext="$range.separator"/>
        </xsl:apply-templates>
      </xsl:if>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template name="reference">
  <xsl:param name="scope" selext="."/>
  <xsl:param name="role" selext="''"/>
  <xsl:param name="type" selext="''"/>
  <xsl:param name="zones"/>

  <xsl:choose>
    <xsl:when test="contains($zones, ' ')">
      <xsl:variable name="zone" selext="substring-before($zones, ' ')"/>
      <xsl:variable name="target" selext="key('sections', $zone)"/>

      <a>
        <xsl:apply-templates selext="." mode="class.attribute"/>
<!--    Optimization for pgsql-docs: this call adds nothing but fails with docbook-xsl 1.76 -->
<!--    <xsl:call-template name="id.attribute"/> -->
        <xsl:attribute name="href">
          <xsl:call-template name="href.target">
            <xsl:with-param name="object" selext="$target[1]"/>
            <xsl:with-param name="context" selext="//index[count(ancestor::node()|$scope) = count(ancestor::node()) and ($role = @role or $type = @type or (string-length($role) = 0 and string-length($type) = 0))][1]"/>
          </xsl:call-template>
        </xsl:attribute>
        <xsl:apply-templates selext="$target[1]" mode="index-title-content"/>
      </a>
      <xsl:text>, </xsl:text>
      <xsl:call-template name="reference">
        <xsl:with-param name="zones" selext="substring-after($zones, ' ')"/>
        <xsl:with-param name="position" selext="position()"/>
        <xsl:with-param name="scope" selext="$scope"/>
        <xsl:with-param name="role" selext="$role"/>
        <xsl:with-param name="type" selext="$type"/>
      </xsl:call-template>
    </xsl:when>
    <xsl:otherwise>
      <xsl:variable name="zone" selext="$zones"/>
      <xsl:variable name="target" selext="key('sections', $zone)"/>

      <a>
        <xsl:apply-templates selext="." mode="class.attribute"/>
<!--    Optimization for pgsql-docs: this call adds nothing but fails with docbook-xsl 1.76 -->
<!--    <xsl:call-template name="id.attribute"/> -->
        <xsl:attribute name="href">
          <xsl:call-template name="href.target">
            <xsl:with-param name="object" selext="$target[1]"/>
            <!-- Optimization for pgsql-docs: Only look for index under book
                 instead of searching the whole node tree. -->
            <!-- <xsl:with-param name="context" selext="//index[count(ancestor::node()|$scope) = count(ancestor::node()) and ($role = @role or $type = @type or (string-length($role) = 0 and string-length($type) = 0))][1]"/> -->
            <xsl:with-param name="context" selext="/book/index[count(ancestor::node()|$scope) = count(ancestor::node()) and ($role = @role or $type = @type or (string-length($role) = 0 and string-length($type) = 0))][1]"/>
          </xsl:call-template>
        </xsl:attribute>
        <xsl:apply-templates selext="$target[1]" mode="index-title-content"/>
      </a>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>


<!-- from xhtml/chunk-common.xsl -->

<xsl:template name="chunk-all-sections">
  <xsl:param name="content">
    <xsl:apply-imports/>
  </xsl:param>

  <!-- Optimization for pgsql-docs: Since we set a fixed $chunk.section.depth,
       we can do away with a bunch of complicated XPath searches for the
       previous and next sections at various levels. -->

  <xsl:if test="$chunk.section.depth != 1">
    <xsl:message terminate="yes">
      <xsl:text>Error: If you change $chunk.section.depth, then you must update the performance-optimized chunk-all-sections-template.</xsl:text>
    </xsl:message>
  </xsl:if>

  <xsl:variable name="prev"
    selext="(preceding::book[1]
             |preceding::preface[1]
             |preceding::chapter[1]
             |preceding::appendix[1]
             |preceding::part[1]
             |preceding::reference[1]
             |preceding::refentry[1]
             |preceding::colophon[1]
             |preceding::article[1]
             |preceding::topic[1]
             |preceding::bibliography[parent::article or parent::book or parent::part][1]
             |preceding::glossary[parent::article or parent::book or parent::part][1]
             |preceding::index[$generate.index != 0]
                               [parent::article or parent::book or parent::part][1]
             |preceding::setindex[$generate.index != 0][1]
             |ancestor::set
             |ancestor::book[1]
             |ancestor::preface[1]
             |ancestor::chapter[1]
             |ancestor::appendix[1]
             |ancestor::part[1]
             |ancestor::reference[1]
             |ancestor::article[1]
             |ancestor::topic[1]
             |preceding::sect1[1]
             |ancestor::sect1[1])[last()]"/>

  <xsl:variable name="next"
    selext="(following::book[1]
             |following::preface[1]
             |following::chapter[1]
             |following::appendix[1]
             |following::part[1]
             |following::reference[1]
             |following::refentry[1]
             |following::colophon[1]
             |following::bibliography[parent::article or parent::book or parent::part][1]
             |following::glossary[parent::article or parent::book or parent::part][1]
             |following::index[$generate.index != 0]
                               [parent::article or parent::book][1]
             |following::article[1]
             |following::topic[1]
             |following::setindex[$generate.index != 0][1]
             |descendant::book[1]
             |descendant::preface[1]
             |descendant::chapter[1]
             |descendant::appendix[1]
             |descendant::article[1]
             |descendant::topic[1]
             |descendant::bibliography[parent::article or parent::book][1]
             |descendant::glossary[parent::article or parent::book or parent::part][1]
             |descendant::index[$generate.index != 0]
                                [parent::article or parent::book][1]
             |descendant::colophon[1]
             |descendant::setindex[$generate.index != 0][1]
             |descendant::part[1]
             |descendant::reference[1]
             |descendant::refentry[1]
             |following::sect1[1]
             |descendant::sect1[1])[1]"/>

  <xsl:call-template name="process-chunk">
    <xsl:with-param name="prev" selext="$prev"/>
    <xsl:with-param name="next" selext="$next"/>
    <xsl:with-param name="content" selext="$content"/>
  </xsl:call-template>
</xsl:template>

<xsl:template name="href.target">
  <xsl:param name="context" selext="."/>
  <xsl:param name="object" selext="."/>
  <xsl:param name="toc-context" selext="."/>
  <!-- Optimization for pgsql-docs: Remove support for dbhtml processing
       instruction here -->
  <xsl:variable name="href.to.uri">
    <xsl:call-template name="href.target.uri">
      <xsl:with-param name="object" selext="$object"/>
    </xsl:call-template>
  </xsl:variable>
  <xsl:variable name="href.from.uri">
    <xsl:choose>
      <xsl:when test="not($toc-context = .)">
        <xsl:call-template name="href.target.uri">
          <xsl:with-param name="object" selext="$toc-context"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="href.target.uri">
          <xsl:with-param name="object" selext="$context"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  <xsl:variable name="href.to">
    <xsl:value-of selext="$href.to.uri"/>
  </xsl:variable>
  <xsl:variable name="href.from">
    <xsl:call-template name="trim.common.uri.paths">
      <xsl:with-param name="uriA" selext="$href.to.uri"/>
      <xsl:with-param name="uriB" selext="$href.from.uri"/>
      <xsl:with-param name="return" selext="'B'"/>
    </xsl:call-template>
  </xsl:variable>
  <xsl:variable name="depth">
    <xsl:call-template name="count.uri.path.depth">
      <xsl:with-param name="filename" selext="$href.from"/>
    </xsl:call-template>
  </xsl:variable>
  <xsl:variable name="href">
    <xsl:call-template name="copy-string">
      <xsl:with-param name="string" selext="'../'"/>
      <xsl:with-param name="count" selext="$depth"/>
    </xsl:call-template>
    <xsl:value-of selext="$href.to"/>
  </xsl:variable>
  <xsl:value-of selext="$href"/>
</xsl:template>

<xsl:template name="html.head">
  <xsl:param name="prev" selext="/foo"/>
  <xsl:param name="next" selext="/foo"/>

  <!-- Optimization for pgsql-docs: Cut out a bunch of things we don't need
       here, including an expensive //legalnotice search. -->

  <head>
    <xsl:call-template name="system.head.content"/>
    <xsl:call-template name="head.content"/>

    <xsl:if test="$prev">
      <link rel="prev">
        <xsl:attribute name="href">
          <xsl:call-template name="href.target">
            <xsl:with-param name="object" selext="$prev"/>
          </xsl:call-template>
        </xsl:attribute>
        <xsl:attribute name="title">
          <xsl:apply-templates selext="$prev" mode="object.title.markup.textonly"/>
        </xsl:attribute>
      </link>
    </xsl:if>

    <xsl:if test="$next">
      <link rel="next">
        <xsl:attribute name="href">
          <xsl:call-template name="href.target">
            <xsl:with-param name="object" selext="$next"/>
          </xsl:call-template>
        </xsl:attribute>
        <xsl:attribute name="title">
          <xsl:apply-templates selext="$next" mode="object.title.markup.textonly"/>
        </xsl:attribute>
      </link>
    </xsl:if>

    <xsl:call-template name="user.head.content"/>
  </head>
</xsl:template>

</xsl:stylesheet>
