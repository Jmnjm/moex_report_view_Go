<?xml version="1.0" encoding="UTF-8"?>
<!-- 1.6.00.00 -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema"
                exclude-result-prefixes="xs" version="2.0" xmlns="http://www.w3.org/1999/xhtml">

    <!--<xsl:output method="html" omit-xml-declaration="yes" indent="yes"/>-->
    <xsl:output method="xml" omit-xml-declaration="yes" indent="yes"/>
    <xsl:template name="replace-str">
        <xsl:param name="char" select="','"/>
        <xsl:param name="replacement">
            <br/>
        </xsl:param>
        <xsl:param name="string"/>
        <xsl:variable name="remaining" select="substring-after($string,$char)"/>
        <xsl:value-of select="substring-before(concat($string,$char),$char)"/>
        <xsl:if test="contains($string,$char)">
            <xsl:copy-of select="$replacement"/>
        </xsl:if>
        <xsl:if test="$remaining">
            <xsl:call-template name="replace-str">
                <xsl:with-param name="string" select="$remaining"/>
                <xsl:with-param name="char" select="$char"/>
                <xsl:with-param name="replacement" select="$replacement"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>

    <xsl:template name="pow">
        <xsl:param name="base"/>
        <xsl:param name="exponent"/>
        <xsl:param name="result"/>
        <xsl:choose>
            <xsl:when test="$exponent = 0">
                <xsl:value-of select="1"/>
            </xsl:when>
            <xsl:when test="$exponent = 1">
                <xsl:value-of select="$result * $base"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="pow">
                    <xsl:with-param name="base" select="$base"/>
                    <xsl:with-param name="exponent" select="$exponent - 1"/>
                    <xsl:with-param name="result" select="$result * $base"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="format-amount">
        <xsl:param name="asset"/>
        <xsl:param name="amount"/>
        <xsl:param name="scale"/>
        <xsl:choose>
            <xsl:when test="$scale and $scale!=''">
                <xsl:variable name="divider">
                    <xsl:call-template name="pow">
                        <xsl:with-param name="base" select="10"/>
                        <xsl:with-param name="exponent" select="$scale"/>
                        <xsl:with-param name="result" select="1"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:value-of select="format-number($amount div $divider, substring(concat('###,##0.', '0000'), 1, 8+$scale))"/>
            </xsl:when>
            <xsl:when test="$asset = 'SLV' or $asset = 'JPY'">
                <xsl:value-of select="format-number($amount, '###,##0')"/>
            </xsl:when>
            <xsl:when test="$asset = 'GLD' or $asset = 'PLD' or $asset = 'PLT'">
                <xsl:value-of select="format-number($amount div 10, '###,##0.0')"/>
            </xsl:when>
            <xsl:when test="$asset = 'XAG'">
                <xsl:value-of select="format-number($amount div 1000, '###,##0.000')"/>
            </xsl:when>
            <xsl:when test="$asset = 'XAU'">
                <xsl:value-of select="format-number($amount div 10000, '###,##0.0000')"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="format-number($amount div 100, '###,##0.00')"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="format-date">
        <xsl:param name="yyyy-mm-dd"/>
        <xsl:choose>
            <xsl:when test="string-length($yyyy-mm-dd)>0">
                <xsl:variable name="yyyy" select="substring-before($yyyy-mm-dd, '-')"/>
                <xsl:variable name="mm-dd" select="substring-after($yyyy-mm-dd, '-')"/>
                <xsl:variable name="mm" select="substring-before($mm-dd, '-')"/>
                <xsl:variable name="dd" select="substring-after($mm-dd, '-')"/>
                <xsl:value-of select="concat($dd, '.',$mm,'.',$yyyy)"/>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    <xsl:template name="in-words">
        <xsl:param name="value"/>
        <xsl:variable name="power" select="0"/>
        <xsl:variable name="value2">
            <xsl:value-of select="translate($value,',','.')"/>
        </xsl:variable>
        <xsl:variable name="result">
            <xsl:choose>
                <xsl:when test="floor($value2) > 0">
                    <xsl:call-template name="float2speech">
                        <xsl:with-param name="value" select="floor($value2)"/>
                        <xsl:with-param name="power" select="0"/>
                    </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'zero '"/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:text> rub. </xsl:text>
            <xsl:choose>
                <xsl:when test="floor($value2)!=$value2">
                    <xsl:variable name="kop" select="round((($value2)-floor($value2))*100)"/>
                    <xsl:choose>
                        <xsl:when test="$kop > 9">
                            <xsl:value-of select="concat($kop,' kop.')"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="concat('0',$kop,' kop.')"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'00 kop.'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:value-of
                select="concat(translate(substring((normalize-space($result)),1,1),'abcdefghijklmnopqrstuvwxyz','ABCDEFGHIJKLMNOPQRSTUVWXYZ'),substring(normalize-space($result),2,string-length($result)))"/>
    </xsl:template>
    <xsl:template name="float2speech">
        <xsl:param name="value"/>
        <xsl:param name="power"/>
        <xsl:variable name="ret" select="' '"/>
        <xsl:variable name="strx">
            <xsl:if test="$power!=0">
                <xsl:variable name="i" select="floor($value)"/>
                <xsl:variable name="x" select="floor(($i mod 100) div 10)"/>
                <xsl:variable name="z">
                    <xsl:choose>
                        <xsl:when test="$x=1">
                            <xsl:number value="5"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$i mod 10"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:variable name="ret2">
                    <xsl:value-of select="concat(' ',$ret)"/>
                </xsl:variable>
                <xsl:choose>
                    <xsl:when test="($value mod 1000)=0">
                        <xsl:value-of select="' '"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:choose>
                            <xsl:when test="$power=1">
                                <xsl:value-of select="concat('thousand',$ret2)"/>
                            </xsl:when>
                            <xsl:when test="$power=2">
                                <xsl:value-of select="concat('million',$ret2)"/>
                            </xsl:when>
                            <xsl:when test="$power=3">
                                <xsl:value-of select="concat('billion',$ret2)"/>
                            </xsl:when>
                            <xsl:when test="$power=4">
                                <xsl:value-of select="concat('trillion',$ret2)"/>
                            </xsl:when>
                        </xsl:choose>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:if>
        </xsl:variable>
        <xsl:variable name="str">
            <xsl:if test="$value > 999">
                <xsl:variable name="vd1" select="floor($value div 1000)"/>
                <xsl:variable name="str">
                    <xsl:call-template name="float2speech">
                        <xsl:with-param name="value" select="$vd1"/>
                        <xsl:with-param name="power" select="$power+1"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:value-of select="$str"/>
            </xsl:if>
        </xsl:variable>
        <xsl:variable name="str2">
            <xsl:call-template name="int2speech">
                <xsl:with-param name="dig"
                                select="number(substring(string(number($value)),string-length(string(number($value)))-2,3))"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:text> </xsl:text>
        <xsl:value-of select="concat(normalize-space($str),' ')"/>
        <xsl:value-of select="$str2"/>
        <xsl:value-of select="$strx"/>
    </xsl:template>
    <xsl:template name="int2speech">
        <xsl:param name="dig"/>
        <xsl:variable name="remainder" select="floor(($dig mod 1000) div 100)"/>
        <xsl:variable name="ret">
            <xsl:choose>
                <xsl:when test="$remainder=1">
                    <xsl:value-of select="'one hundred '"/>
                </xsl:when>
                <xsl:when test="$remainder=2">
                    <xsl:value-of select="'two hundred '"/>
                </xsl:when>
                <xsl:when test="$remainder=3">
                    <xsl:value-of select="'three hundred '"/>
                </xsl:when>
                <xsl:when test="$remainder=4">
                    <xsl:value-of select="'four hundred '"/>
                </xsl:when>
                <xsl:when test="$remainder=5">
                    <xsl:value-of select="'five hundred '"/>
                </xsl:when>
                <xsl:when test="$remainder=6">
                    <xsl:value-of select="'six hundred '"/>
                </xsl:when>
                <xsl:when test="$remainder=7">
                    <xsl:value-of select="'seven hundred '"/>
                </xsl:when>
                <xsl:when test="$remainder=8">
                    <xsl:value-of select="'eight hundred '"/>
                </xsl:when>
                <xsl:when test="$remainder=9">
                    <xsl:value-of select="'nine hundred '"/>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="remainder2" select="floor(($dig mod 100) div 10)"/>
        <xsl:variable name="remainder3" select="floor($dig mod 10)"/>
        <xsl:variable name="ret2">
            <xsl:choose>
                <xsl:when test="$remainder2=1">
                    <xsl:choose>
                        <xsl:when test="$remainder3=0">
                            <xsl:value-of select="'ten '"/>
                        </xsl:when>
                        <xsl:when test="$remainder3=1">
                            <xsl:value-of select="'eleven '"/>
                        </xsl:when>
                        <xsl:when test="$remainder3=2">
                            <xsl:value-of select="'twelve '"/>
                        </xsl:when>
                        <xsl:when test="$remainder3=3">
                            <xsl:value-of select="'thirteen '"/>
                        </xsl:when>
                        <xsl:when test="$remainder3=4">
                            <xsl:value-of select="'fourteen '"/>
                        </xsl:when>
                        <xsl:when test="$remainder3=5">
                            <xsl:value-of select="'fifteen '"/>
                        </xsl:when>
                        <xsl:when test="$remainder3=6">
                            <xsl:value-of select="'sixteen '"/>
                        </xsl:when>
                        <xsl:when test="$remainder3=7">
                            <xsl:value-of select="'seventeen '"/>
                        </xsl:when>
                        <xsl:when test="$remainder3=8">
                            <xsl:value-of select="'eighteen '"/>
                        </xsl:when>
                        <xsl:when test="$remainder3=9">
                            <xsl:value-of select="'nineteen '"/>
                        </xsl:when>
                    </xsl:choose>
                </xsl:when>
                <xsl:when test="$remainder2=2">
                    <xsl:value-of select="'twenty '"/>
                </xsl:when>
                <xsl:when test="$remainder2=3">
                    <xsl:value-of select="'thirty '"/>
                </xsl:when>
                <xsl:when test="$remainder2=4">
                    <xsl:value-of select="'forty '"/>
                </xsl:when>
                <xsl:when test="$remainder2=5">
                    <xsl:value-of select="'fifty '"/>
                </xsl:when>
                <xsl:when test="$remainder2=6">
                    <xsl:value-of select="'sixty '"/>
                </xsl:when>
                <xsl:when test="$remainder2=7">
                    <xsl:value-of select="'seventy '"/>
                </xsl:when>
                <xsl:when test="$remainder2=8">
                    <xsl:value-of select="'eighty '"/>
                </xsl:when>
                <xsl:when test="$remainder2=9">
                    <xsl:value-of select="'ninety '"/>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="ret3">
            <xsl:choose>
                <xsl:when test="$remainder2!=1">
                    <xsl:choose>
                        <xsl:when test="$remainder3=1">
                            <xsl:value-of select="'one '"/>
                        </xsl:when>
                        <xsl:when test="$remainder3=2">
                            <xsl:value-of select="'two '"/>
                        </xsl:when>
                        <xsl:when test="$remainder3=3">
                            <xsl:value-of select="'three '"/>
                        </xsl:when>
                        <xsl:when test="$remainder3=4">
                            <xsl:value-of select="'four '"/>
                        </xsl:when>
                        <xsl:when test="$remainder3=5">
                            <xsl:value-of select="'five '"/>
                        </xsl:when>
                        <xsl:when test="$remainder3=6">
                            <xsl:value-of select="'six '"/>
                        </xsl:when>
                        <xsl:when test="$remainder3=7">
                            <xsl:value-of select="'seven '"/>
                        </xsl:when>
                        <xsl:when test="$remainder3=8">
                            <xsl:value-of select="'eight '"/>
                        </xsl:when>
                        <xsl:when test="$remainder3=9">
                            <xsl:value-of select="'nine '"/>
                        </xsl:when>
                    </xsl:choose>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:value-of select="concat($ret,$ret2,$ret3)"/>
    </xsl:template>
    <xsl:template match="/">

        <html>
            <head>
                <meta charset="utf-8"/>
                <style type="text/css">

                    table { border-collapse: collapse; }

                    .notice td, .notice th { border: 1px solid black; text-align:center; }
                    .notice th { background-color: #eee; text-align:center; }

                    .notice1 td, .notice1 th { border:#000 1px solid; padding:10px 10px; vertical-align:top;}


                    <!-- RUB -->

                    tr
                    {mso-height-source:auto;}
                    col
                    {mso-width-source:auto;}

                    span { font-size:11pt}

                    td
                    {mso-style-parent:style0;
                    padding-top:1px;
                    padding-right:1px;
                    padding-left:1px;
                    mso-ignore:padding;
                    color:#000;
                    font-size:10.0pt;
                    font-weight:400;
                    font-style:normal;
                    text-decoration:none;
                    font-family: Arial, sans-serif;
                    mso-generic-font-family:auto;
                    mso-font-charset:204;
                    mso-number-format:\@ !important;
                    text-align:general;
                    vertical-align:bottom;
                    border:none;
                    mso-background-source:auto;
                    mso-pattern:auto;
                    mso-protection:locked visible;
                    white-space: normal;
                    mso-rotate:0;}

                    br {mso-data-placement:same-cell;}

                    .xl65
                    {mso-style-parent:style0;
                    font-family: Arial, sans-serif;
                    mso-font-charset:204;}
                    .xl66
                    {mso-style-parent:style0;
                    font-family: Arial, sans-serif;
                    mso-font-charset:204;
                    text-align:center;
                    vertical-align:middle;
                    border:.5pt solid #000;}
                    .xl67
                    {mso-style-parent:style0;
                    font-family: Arial, sans-serif;
                    mso-font-charset:204;
                    text-align:center;}
                    .xl68
                    {mso-style-parent:style0;
                    font-family: Arial, sans-serif;
                    mso-font-charset:204;
                    text-align:center;
                    vertical-align:middle;}
                    .xl69
                    {mso-style-parent:style0;
                    font-family: Arial, sans-serif;
                    mso-font-charset:204;
                    vertical-align:top;
                    border-top:none;
                    border-right:.5pt solid #000;
                    border-bottom:.5pt solid #000;
                    border-left:none;
                    white-space:normal;}
                    .xl70
                    {mso-style-parent:style0;
                    font-family: Arial, sans-serif;
                    mso-font-charset:204;
                    text-align:center;
                    vertical-align:middle;
                    border-top:none;
                    border-right:.5pt solid #000;
                    border-bottom:.5pt solid #000;
                    border-left:none;}
                    .xl71
                    {mso-style-parent:style0;
                    font-family: Arial, sans-serif;
                    mso-font-charset:204;
                    border-top:none;
                    border-right:none;
                    border-bottom:.5pt solid #000;
                    border-left:none;
                    vertical-align: middle;}
                    .xl72
                    {mso-style-parent:style0;
                    font-family: Arial, sans-serif;
                    mso-font-charset:204;
                    text-align:center;
                    vertical-align:top;}
                    .xl73
                    {mso-style-parent:style0;
                    font-size:8.0pt;
                    font-family: Arial, sans-serif;
                    mso-font-charset:204;
                    text-align:center;
                    vertical-align:top;
                    border-top:.5pt solid #000;
                    border-right:none;
                    border-bottom:none;
                    border-left:none;}
                    .xl74
                    {mso-style-parent:style0;
                    font-size:12.0pt;
                    font-weight:700;
                    font-family: Arial, sans-serif;
                    mso-font-charset:204;}
                    .xl75
                    {mso-style-parent:style0;
                    font-weight:400;
                    font-family: Arial, sans-serif;
                    mso-font-charset:204;
                    text-align:center;}
                    .xl76
                    {mso-style-parent:style0;
                    font-family: Arial, sans-serif;
                    mso-font-charset:204;
                    vertical-align:top;
                    border-top:none;
                    border-right:none;
                    border-bottom:none;
                    border-left:.5pt solid #000;
                    white-space:normal;}
                    .xl77
                    {mso-style-parent:style0;
                    font-family: Arial, sans-serif;
                    mso-font-charset:204;
                    border-top:.5pt solid #000;
                    border-right:.5pt solid #000;
                    border-bottom:.5pt solid #000;
                    border-left:none;
                    vertical-align:middle;}
                    .xl78
                    {mso-style-parent:style0;
                    font-family: Arial, sans-serif;
                    mso-font-charset:204;
                    vertical-align:middle;
                    border-top:.5pt solid #000;
                    border-right:.5pt hairline #000;
                    border-bottom:.5pt solid #000;
                    border-left:none;
                    white-space:normal;}
                    .xl79
                    {mso-style-parent:style0;
                    font-family: Arial, sans-serif;
                    mso-font-charset:204;
                    border:.5pt solid #000;}
                    .xl80
                    {mso-style-parent:style0;
                    font-family: Arial, sans-serif;
                    mso-font-charset:204;
                    border-top:.5pt solid #000;
                    border-right:none;
                    border-bottom:none;
                    border-left:.5pt solid #000;}
                    .xl81
                    {mso-style-parent:style0;
                    font-family: Arial, sans-serif;
                    mso-font-charset:204;
                    vertical-align:top;
                    border-top:none;
                    border-right:.5pt solid #000;
                    border-bottom:none;
                    border-left:none;
                    white-space:normal;}
                    .xl82
                    {mso-style-parent:style0;
                    font-family: Arial, sans-serif;
                    mso-font-charset:204;
                    mso-number-format:"\@";
                    border-top:.5pt solid #000;
                    border-right:none;
                    border-bottom:none;
                    border-left:none;}
                    .xl83
                    {mso-style-parent:style0;
                    font-family: Arial, sans-serif;
                    mso-font-charset:204;
                    border-top:none;
                    border-right:.5pt solid #000;
                    border-bottom:.5pt solid #000;
                    border-left:none;}
                    .xl84
                    {mso-style-parent:style0;
                    font-family: Arial, sans-serif;
                    mso-font-charset:204;
                    vertical-align:top;
                    border-top:.5pt solid #000;
                    border-right:.5pt solid #000;
                    border-bottom:none;
                    border-left:none;
                    white-space:normal;}
                    .xl85
                    {mso-style-parent:style0;
                    font-family: Arial, sans-serif;
                    mso-font-charset:204;
                    text-align:left;
                    vertical-align:middle;
                    border:.5pt solid #000;}
                    .xl86
                    {mso-style-parent:style0;
                    font-family: Arial, sans-serif;
                    mso-font-charset:204;
                    border-top:.5pt solid #000;
                    border-right:none;
                    border-bottom:none;
                    border-left:none;}
                    .xl87
                    {mso-style-parent:style0;
                    font-family: Arial, sans-serif;
                    mso-font-charset:204;
                    text-align:left;
                    vertical-align:middle;
                    border-top:none;
                    border-right:.5pt solid #000;
                    border-bottom:.5pt solid #000;
                    border-left:none;}
                    .xl88
                    {mso-style-parent:style0;
                    font-family: Arial, sans-serif;
                    mso-font-charset:204;
                    text-align:left;
                    vertical-align:middle;
                    border-top:none;
                    border-right:.5pt hairline #000;
                    border-bottom:.5pt solid #000;
                    border-left:none;
                    white-space:normal;}
                    .xl89
                    {mso-style-parent:style0;
                    font-family: Arial, sans-serif;
                    mso-font-charset:204;
                    border-top:.5pt solid #000;
                    border-right:.5pt solid #000;
                    border-bottom:none;
                    border-left:.5pt solid #000;}
                    .xl90
                    {mso-style-parent:style0;
                    font-family: Arial, sans-serif;
                    mso-font-charset:204;
                    border-top:none;
                    border-right:.5pt solid #000;
                    border-bottom:none;
                    border-left:.5pt solid #000;}
                    .xl91
                    {mso-style-parent:style0;
                    font-family: Arial, sans-serif;
                    mso-font-charset:204;
                    border-top:none;
                    border-right:none;
                    border-bottom:none;
                    border-left:.5pt solid #000;}
                    .xl92
                    {mso-style-parent:style0;
                    font-family: Arial, sans-serif;
                    mso-font-charset:204;
                    border-top:none;
                    border-right:.5pt solid #000;
                    border-bottom:.5pt solid #000;
                    border-left:.5pt solid #000;}
                    .xl93
                    {mso-style-parent:style0;
                    font-family: Arial, sans-serif;
                    mso-font-charset:204;
                    text-align:center;
                    border-top:.5pt solid #000;
                    border-right:none;
                    border-bottom:none;
                    border-left:none;}
                    .xl94
                    {mso-style-parent:style0;
                    border-top:.5pt solid #000;
                    border-right:none;
                    border-bottom:none;
                    border-left:none;}
                    .xl95
                    {mso-style-parent:style0;
                    font-family: Arial, sans-serif;
                    mso-font-charset:204;
                    text-align:center;
                    vertical-align:middle;
                    border-top:.5pt solid #000;
                    border-right:none;
                    border-bottom:.5pt solid #000;
                    border-left:.5pt solid #000;}
                    .xl96
                    {mso-style-parent:style0;
                    font-family: Arial, sans-serif;
                    mso-font-charset:204;
                    vertical-align:top;
                    white-space:normal;}
                    .xl97
                    {mso-style-parent:style0;
                    font-family: Arial, sans-serif;
                    mso-font-charset:204;
                    border-top:.5pt solid #000;
                    border-right:.5pt solid #000;
                    border-bottom:.5pt solid #000;
                    border-left:none;
                    vertical-align:top;
                    padding-top:6pt}

                </style>
            </head>
            <body link="#0563C1" vlink="#954F72" class="xl65">
                <xsl:for-each select="/*">
                    <span>
                        NOTICE №
                        <xsl:value-of select="@DocNum"/> OF COLLATERAL ACCOUNT DEBIT AND CREDIT
                    </span>
                    <br/>
                    <br/>
                    <span>Clearing Member name:
                        <xsl:value-of select="@MemberName"/>
                    </span>
                    <br/>
                    <span>Clearing Member code:
                        <xsl:value-of select="@Member"/>
                    </span>
                    <br/>
                    <br/>

                    <xsl:choose>
                        <xsl:when test="@Asset = 'RUB'">
                            <xsl:variable name="Sum" select="(@*[name()='Sum' and string-length(normalize-space(name())) > 0][1]) div 100"/>
                            <xsl:choose>
                                <xsl:when test="@TransKind = '01'">
                                    <xsl:variable name="documentCode">0401060</xsl:variable>
                                    <xsl:variable name="paymentKind"></xsl:variable>
                                    <xsl:variable name="paymentOrder">5</xsl:variable>
                                    <table border="0" cellpadding="0" cellspacing="0" width="672"
                                           style='border-collapse:collapse; table-layout:fixed; width:504pt'>
                                        <col class="xl65" width="75"
                                             style='mso-width-source:userset;mso-width-alt:2742; width:56pt'/>
                                        <col class="xl65" width="34"
                                             style='mso-width-source:userset;mso-width-alt:1243; width:26pt'/>
                                        <col class="xl65" width="19"
                                             style='mso-width-source:userset;mso-width-alt:694; width:14pt'/>
                                        <col class="xl65" width="39"
                                             style='mso-width-source:userset;mso-width-alt:1426; width:29pt'/>
                                        <col class="xl65" width="20"
                                             style='mso-width-source:userset;mso-width-alt:731; width:15pt'/>
                                        <col class="xl65" width="34"
                                             style='mso-width-source:userset;mso-width-alt:1243; width:26pt'/>
                                        <col class="xl65" width="55"
                                             style='mso-width-source:userset;mso-width-alt:2011; width:41pt'/>
                                        <col class="xl65" width="39"
                                             style='mso-width-source:userset;mso-width-alt:1426; width:29pt'/>
                                        <col class="xl65" width="31"
                                             style='mso-width-source:userset;mso-width-alt:1133; width:23pt'/>
                                        <col class="xl65" width="27"
                                             style='mso-width-source:userset;mso-width-alt:987; width:20pt'/>
                                        <col class="xl65" width="37"
                                             style='mso-width-source:userset;mso-width-alt:1353; width:28pt'/>
                                        <col class="xl65" width="19" span="3"
                                             style='mso-width-source:userset;mso-width-alt: 694;width:14pt'/>
                                        <col class="xl65" width="37" span="2"
                                             style='mso-width-source:userset;mso-width-alt: 1353;width:28pt'/>
                                        <col class="xl65" width="21"
                                             style='mso-width-source:userset;mso-width-alt:768; width:16pt'/>
                                        <col class="xl65" width="17"
                                             style='mso-width-source:userset;mso-width-alt:621; width:13pt'/>
                                        <col class="xl65" width="24"
                                             style='mso-width-source:userset;mso-width-alt:877; width:18pt'/>
                                        <col class="xl65" width="32"
                                             style='mso-width-source:userset;mso-width-alt:1170; width:24pt'/>
                                        <col class="xl65" width="9"
                                             style='mso-width-source:userset;mso-width-alt:329; width:7pt'/>
                                        <col class="xl65" width="28"
                                             style='mso-width-source:userset;mso-width-alt:1024; width:21pt'/>
                                        <col class="xl65" width="5"
                                             style='mso-width-source:userset;mso-width-alt:182; width:4pt'/>
                                        <tr style='mso-height-source:userset;height:10pt'>
                                            <td/>
                                        </tr>
                                        <tr height="20" style='mso-height-source:userset;height:15.0pt'>
                                            <td colspan="3" height="20" class="xl65" width="128"
                                                style='height:15.0pt;width:96pt; text-align:center'>
                                                <span>
                                                    <xsl:call-template name="format-date">
                                                        <xsl:with-param name="yyyy-mm-dd" select="@AccDocDate"/>
                                                    </xsl:call-template>
                                                </span>
                                            </td>
                                            <td class="xl65" width="39" style='width:29pt'/>
                                            <td class="xl65" width="20" style='width:15pt'/>
                                            <td colspan="3" class="xl65" width="128"
                                                style='width:96pt; text-align:center'>
                                                <span>
                                                    <xsl:call-template name="format-date">
                                                        <xsl:with-param name="yyyy-mm-dd" select="@TransDate"/>
                                                    </xsl:call-template>
                                                </span>
                                            </td>
                                            <td class="xl65" width="31" style='width:23pt'/>
                                            <td class="xl65" width="27" style='width:20pt'/>
                                            <td class="xl65" width="37" style='width:28pt'/>
                                            <td class="xl65" width="19" style='width:14pt'/>
                                            <td class="xl65" width="19" style='width:14pt'/>
                                            <td class="xl65" width="19" style='width:14pt'/>
                                            <td class="xl65" width="37" style='width:28pt'/>
                                            <td class="xl65" width="37" style='width:28pt'/>
                                            <td class="xl65" width="21" style='width:16pt'/>
                                            <td class="xl65" width="17" style='width:13pt'/>
                                            <td class="xl65" width="24" style='width:18pt'/>
                                            <td colspan="3" class="xl66" width="69" style='width:52pt'>
                                                <span>
                                                    <xsl:value-of select="$documentCode"/>
                                                </span>
                                            </td>
                                        </tr>
                                        <tr height="13" style='mso-height-source:userset;height:9.75pt'>
                                            <td colspan="3" height="13" class="xl73" style='height:9.75pt'>posted</td>
                                            <td class="xl65"/>
                                            <td class="xl65"/>
                                            <td colspan="3" class="xl73">withdrawn</td>
                                            <td class="xl65"/>
                                            <td class="xl65"/>
                                            <td class="xl65"/>
                                            <td class="xl65"/>
                                            <td class="xl65"/>
                                            <td class="xl65"/>
                                            <td class="xl65"/>
                                            <td class="xl65"/>
                                            <td class="xl65"/>
                                            <td class="xl65"/>
                                            <td class="xl65"/>
                                            <td class="xl65"/>
                                            <td class="xl65"/>
                                            <td class="xl65"/>
                                        </tr>
                                        <tr height="19" style='mso-height-source:userset;height:14.65pt'>
                                            <td colspan="8" rowspan="2" height="45" class="xl74" style='height:34.55pt'>
                                                PAY ORDER №
                                                <xsl:value-of select="@AccDocNo"/>
                                            </td>
                                            <td colspan="5" rowspan="2" class="xl75">
                                                <span>
                                                    <xsl:call-template name="format-date">
                                                        <xsl:with-param name="yyyy-mm-dd" select="@AccDocDate"/>
                                                    </xsl:call-template>
                                                </span>
                                            </td>
                                            <td class="xl65"/>
                                            <td colspan="5" rowspan="2" class="xl67">
                                                <span>
                                                    <xsl:value-of select="$paymentKind"/>
                                                </span>
                                            </td>
                                            <td class="xl65"/>
                                            <td class="xl65"/>
                                            <td class="xl65"/>
                                        </tr>
                                        <tr height="26" style='mso-height-source:userset;height:19.9pt'>
                                            <td height="26" class="xl65" style='height:19.9pt'/>
                                            <td class="xl65"/>
                                            <td class="xl68"/>
                                            <td class="xl66"><![CDATA[ ]]></td>
                                        </tr>
                                        <tr height="19" style='mso-height-source:userset;height:14.25pt'>
                                            <td height="19" class="xl65" style='height:14.25pt'/>
                                            <td class="xl65"/>
                                            <td class="xl65"/>
                                            <td class="xl65"/>
                                            <td class="xl65"/>
                                            <td class="xl65"/>
                                            <td class="xl65"/>
                                            <td class="xl65"/>
                                            <td colspan="5" class="xl73">Date</td>
                                            <td class="xl65"/>
                                            <td colspan="5" class="xl73">Kind of payment</td>
                                            <td class="xl65"/>
                                            <td class="xl68"/>
                                            <td class="xl65"/>
                                        </tr>
                                        <tr height="58" style='mso-height-source:userset;height:43.5pt'>
                                            <td height="58" class="xl69" width="75" style='height:43.5pt; width:16pt;'>
                                                Amount expressed in words
                                            </td>
                                            <td colspan="21" class="xl76" width="597"
                                                style='border-left:none;width:448pt'>
                                                <span>
                                                    <xsl:call-template name="in-words">
                                                        <xsl:with-param name="value" select="$Sum"/>
                                                    </xsl:call-template>
                                                </span>
                                            </td>
                                        </tr>
                                        <tr height="18" style='mso-height-source:userset;height:13.9pt'>
                                            <td colspan="5" height="18" class="xl77" style='height:13.9pt'>Taxpayer
                                                identification number
                                                <br/>
                                                <span>
                                                    <xsl:value-of
                                                            select="*[local-name() = 'AccountRU']/*[local-name() = 'Payer']/@INN"/>
                                                </span>
                                            </td>
                                            <td colspan="5" class="xl78" width="186" style='width:139pt'>Tax
                                                registration reason code
                                                <br/>
                                                <span>
                                                    <xsl:value-of
                                                            select="*[local-name() = 'AccountRU']/*[local-name() = 'Payer']/@KPP"/>
                                                </span>
                                            </td>
                                            <td colspan="2" rowspan="2" class="xl79" style=" vertical-align:top">
                                                Amount
                                            </td>
                                            <td colspan="10" rowspan="2" class="xl80" style=" vertical-align:top">
                                                <span>
                                                    <xsl:call-template name="format-amount">
                                                        <xsl:with-param name="amount" select="@Sum"/>
                                                        <xsl:with-param name="asset" select="@Asset"/>
                                                        <xsl:with-param name="scale" select="2"/>
                                                    </xsl:call-template>
                                                </span>
                                            </td>
                                        </tr>
                                        <tr height="38" style='mso-height-source:userset;height:28.9pt'>
                                            <td colspan="10" rowspan="2" height="86" class="xl81" width="373"
                                                style='height:64.9pt; width:279pt;'>
                                                <span style='mso-spacerun:yes'>
                                                    <xsl:value-of
                                                            select="*[local-name() = 'AccountRU']/*[local-name() = 'Payer']/@Name"/>
                                                </span>
                                            </td>
                                        </tr>
                                        <tr height="48" style='mso-height-source:userset;height:36.0pt'>
                                            <td colspan="2" rowspan="2" height="65" class="xl79" style='height:48.75pt'>
                                                Account<br/>number
                                            </td>
                                            <td colspan="10" rowspan="2" class="xl82">
                                                <span>
                                                    <xsl:value-of
                                                            select="*[local-name() = 'AccountRU']/*[local-name() = 'Payer']/@PersonalAcc"/>
                                                </span>
                                            </td>
                                        </tr>
                                        <tr height="17" style='height:12.75pt'>
                                            <td colspan="10" height="17" class="xl83" style='height:12.75pt'>Payer</td>
                                        </tr>
                                        <tr height="20" style='mso-height-source:userset;height:15.0pt'>
                                            <td colspan="10" rowspan="2" height="42" class="xl84" width="373"
                                                style='height:31.9pt; width:279pt;'>
                                                <span>
                                                    <xsl:value-of
                                                            select="*[local-name() = 'AccountRU']/*[local-name() = 'Payer']/*[local-name() = 'Bank']/@Name"/>
                                                </span>
                                            </td>
                                            <td colspan="2" class="xl85" style='border-left:none'>RCBIC</td>
                                            <td colspan="10" class="xl65">
                                                <span>
                                                    <xsl:value-of
                                                            select="*[local-name() = 'AccountRU']/*[local-name() = 'Payer']/*[local-name() = 'Bank']/@BIC"/>
                                                </span>
                                            </td>
                                        </tr>
                                        <tr height="22" style='mso-height-source:userset;height:16.9pt'>
                                            <td colspan="2" rowspan="2" height="39" class="xl79" style='height:29.65pt'>
                                                Account<br/>number
                                            </td>
                                            <td colspan="10" rowspan="2" class="xl71" style=" vertical-align:bottom">
                                                <span>
                                                    <xsl:value-of
                                                            select="*[local-name() = 'AccountRU']/*[local-name() = 'Payer']/*[local-name() = 'Bank']/@CorrespAcc"/>
                                                </span>
                                            </td>
                                        </tr>
                                        <tr height="17" style='height:12.75pt'>
                                            <td colspan="10" height="17" class="xl83" style='height:12.75pt'>Payer’s
                                                bank
                                            </td>
                                        </tr>
                                        <tr height="21" style='mso-height-source:userset;height:15.75pt'>
                                            <td colspan="10" rowspan="2" height="46" class="xl84" width="373"
                                                style='height:34.9pt; width:279pt;'>
                                                <span>
                                                    <xsl:value-of
                                                            select="*[local-name() = 'AccountRU']/*[local-name() = 'Payee']/*[local-name() = 'Bank']/@Name"/>
                                                </span>
                                            </td>
                                            <td colspan="2" class="xl85" style='border-left:none'>RCBIC</td>
                                            <td colspan="10" class="xl86">
                                                <span>
                                                    <xsl:value-of
                                                            select="*[local-name() = 'AccountRU']/*[local-name() = 'Payee']/*[local-name() = 'Bank']/@BIC"/>
                                                </span>
                                            </td>
                                        </tr>
                                        <tr height="25" style='mso-height-source:userset;height:19.15pt'>
                                            <td colspan="2" rowspan="2" height="42" class="xl79" style='height:31.9pt'>
                                                Account<br/>number
                                            </td>
                                            <td colspan="10" rowspan="2" class="xl65">
                                                <span style='mso-spacerun:yes'>
                                                    <xsl:value-of
                                                            select="*[local-name() = 'AccountRU']/*[local-name() = 'Payee']/*[local-name() = 'Bank']/@CorrespAcc"/>
                                                </span>
                                            </td>
                                        </tr>
                                        <tr height="17" style='height:12.75pt'>
                                            <td colspan="10" height="17" class="xl83" style='height:12.75pt'>
                                                Payee's bank
                                            </td>
                                        </tr>
                                        <tr height="18" style='mso-height-source:userset;height:13.9pt'>
                                            <td colspan="5" height="18" class="xl87" style='height:13.9pt'>Taxpayer
                                                identification number
                                                <br/>
                                                <span style='mso-spacerun:yes'>
                                                    <xsl:value-of
                                                            select="*[local-name() = 'AccountRU']/*[local-name() = 'Payee']/@INN"/>
                                                </span>
                                            </td>
                                            <td colspan="5" class="xl88" width="186" style='width:139pt'>Tax
                                                registration reason code
                                                <br/>
                                                <span style='mso-spacerun:yes'>
                                                    <xsl:value-of
                                                            select="*[local-name() = 'AccountRU']/*[local-name() = 'Payee']/@KPP"/>
                                                </span>
                                            </td>
                                            <td colspan="2" rowspan="2" class="xl79" style="vertical-align:top">Account
                                                <br/>number
                                            </td>
                                            <td colspan="10" rowspan="2" class="xl65" style="vertical-align:top">
                                                <span>
                                                    <xsl:value-of
                                                            select="*[local-name() = 'AccountRU']/*[local-name() = 'Payee']/@PersonalAcc"/>
                                                </span>
                                            </td>
                                        </tr>
                                        <tr height="38" style='mso-height-source:userset;height:28.9pt'>
                                            <td colspan="10" rowspan="4" height="86" class="xl81" width="373"
                                                style='height:64.9pt; width:279pt;'>
                                                <span>
                                                    <xsl:value-of
                                                            select="*[local-name() = 'AccountRU']/*[local-name() = 'Payee']/@Name"/>
                                                </span>
                                            </td>
                                        </tr>
                                        <tr height="20" style='mso-height-source:userset;height:15.0pt'>
                                            <td colspan="2" height="20" class="xl79"
                                                style='height:15.0pt;border-left:none'>Transact<br/>ion type
                                            </td>
                                            <td colspan="3" class="xl89" style='border-left:none'>
                                                <span>
                                                    <xsl:value-of select="@TransKind"/>
                                                </span>
                                            </td>
                                            <td colspan="3" class="xl80" style='border-left:none'>Period of<br/>payment
                                            </td>
                                            <td colspan="4" class="xl80"></td>
                                        </tr>
                                        <tr height="20" style='mso-height-source:userset;height:15.0pt'>
                                            <td colspan="2" height="20" class="xl79"
                                                style='height:15.0pt;border-left:none'>Payment<br/>purpose
                                            </td>
                                            <td colspan="3" class="xl90" style='border-left:none'><![CDATA[ ]]></td>
                                            <td colspan="3" class="xl79" style='border-left:none'>Payment<br/>batch
                                            </td>
                                            <td colspan="4" class="xl91" style='border-left:none'>
                                                <span>
                                                    <xsl:value-of select="$paymentOrder"/>
                                                </span>
                                            </td>
                                        </tr>
                                        <tr height="8" style='mso-height-source:userset;height:6.0pt'>
                                            <td colspan="2" rowspan="2" height="25" class="xl79" style='height:18.75pt'>
                                                Code
                                            </td>
                                            <td colspan="3" rowspan="2" class="xl92"><![CDATA[ ]]></td>
                                            <td colspan="3" rowspan="2" class="xl79">Extra field</td>
                                            <td colspan="4" rowspan="2" class="xl91"><![CDATA[ ]]></td>
                                        </tr>
                                        <tr height="17" style='height:12.75pt'>
                                            <td colspan="10" height="17" class="xl83" style='height:12.75pt'>
                                                Payee
                                            </td>
                                        </tr>
                                        <tr height="20" style='mso-height-source:userset;height:15.0pt'>
                                            <td colspan="4" height="20" class="xl70" style='height:15.0pt'>
                                                <![CDATA[ ]]></td>
                                            <td colspan="3" class="xl70"><![CDATA[ ]]></td>
                                            <td class="xl70"><![CDATA[ ]]></td>
                                            <td colspan="3" class="xl70"><![CDATA[ ]]></td>
                                            <td colspan="5" class="xl66" style='border-left:none'><![CDATA[ ]]></td>
                                            <td colspan="4" class="xl66" style='border-left:none'><![CDATA[ ]]></td>
                                            <td colspan="2" class="xl95" style='border-left:none'><![CDATA[ ]]></td>
                                        </tr>
                                        <tr height="95" style='mso-height-source:userset;height:71.65pt'>
                                            <td colspan="22" height="95" class="xl96" width="672" style='height:71.65pt;
  width:504pt'>
                                                <span>
                                                    <xsl:value-of select="@Details"/>
                                                </span>
                                            </td>
                                        </tr>
                                        <tr height="16" style='mso-height-source:userset;height:12.4pt'>
                                            <td colspan="22" height="16" class="xl71" style='height:12.4pt'>Payment
                                                purpose
                                            </td>
                                        </tr>
                                        <tr height="14" style='mso-height-source:userset;height:10.5pt'>
                                            <td height="14" class="xl65" style='height:10.5pt'/>
                                            <td class="xl68"/>
                                            <td class="xl65"/>
                                            <td class="xl65"/>
                                            <td class="xl65"/>
                                            <td colspan="6" class="xl93">Signature mark</td>
                                            <td class="xl67"/>
                                            <td class="xl67"/>
                                            <td class="xl65"/>
                                            <td class="xl65" colspan="8">marked by the bank as executed</td>
                                        </tr>
                                        <tr height="44" style='mso-height-source:userset;height:33.0pt'>
                                            <td height="44" class="xl65" style='height:33.0pt'/>
                                            <td class="xl67"/>
                                            <td class="xl65"/>
                                            <td class="xl65"/>
                                            <td class="xl65"/>
                                            <td class="xl71"><![CDATA[ ]]></td>
                                            <td class="xl71"><![CDATA[ ]]></td>
                                            <td class="xl71"><![CDATA[ ]]></td>
                                            <td class="xl71"><![CDATA[ ]]></td>
                                            <td class="xl71"><![CDATA[ ]]></td>
                                            <td class="xl71"><![CDATA[ ]]></td>
                                            <td class="xl65"/>
                                            <td class="xl65"/>
                                            <td class="xl65"/>
                                            <td class="xl65"/>
                                            <td class="xl65"/>
                                            <td class="xl65"/>
                                            <td class="xl65"/>
                                            <td class="xl65"/>
                                            <td class="xl65"/>
                                            <td class="xl65"/>
                                            <td class="xl65"/>
                                        </tr>
                                        <tr height="58" style='mso-height-source:userset;height:43.5pt'>
                                            <td height="58" class="xl68" style='height:43.5pt'/>
                                            <td class="xl72"><span style='mso-spacerun:yes'> </span>seal</td>
                                            <td class="xl65"/>
                                            <td class="xl65"/>
                                            <td class="xl65"/>
                                            <td class="xl71"><![CDATA[ ]]></td>
                                            <td class="xl71"><![CDATA[ ]]></td>
                                            <td class="xl71"><![CDATA[ ]]></td>
                                            <td class="xl71"><![CDATA[ ]]></td>
                                            <td class="xl71"><![CDATA[ ]]></td>
                                            <td class="xl71"><![CDATA[ ]]></td>
                                            <td class="xl65"/>
                                            <td class="xl65"/>
                                            <td class="xl65"/>
                                            <td class="xl65"/>
                                            <td class="xl65"/>
                                            <td class="xl65"/>
                                            <td class="xl65"/>
                                            <td class="xl65"/>
                                            <td class="xl65"/>
                                            <td class="xl65"/>
                                            <td class="xl65"/>
                                        </tr>
                                        <tr>
                                            <td colspan="22" style="height:35pt"><![CDATA[ ]]></td>
                                        </tr>

                                        <tr style='mso-height-source:userset;height:70pt'>
                                            <td colspan="2" style="vertical-align:middle;">Payer’s / Beneficiary’s
                                                account
                                            </td>
                                            <td colspan="6" style="vertical-align:middle;">
                                                <span>
                                                    <xsl:value-of select="@Account"/>
                                                </span>
                                            </td>
                                            <td colspan="6" style="vertical-align:middle;">Account details</td>
                                            <td colspan="8" style="vertical-align:middle;">
                                                <span>
                                                    <xsl:value-of select="@AccountName"/>
                                                </span>
                                            </td>
                                        </tr>

                                        <tr>
                                            <td colspan="22" style="height:25pt"><![CDATA[ ]]></td>
                                        </tr>
                                        <xsl:choose>
                                            <xsl:when test="*[local-name() = 'CRegListList']">
                                                <tr>
                                                    <td colspan="6" style="vertical-align:middle;">Clearing Register’s
                                                        Code (1 or >1)
                                                        <br/>
                                                        2nd, 3rd level Settlement Code
                                                    </td>
                                                    <td colspan="2"
                                                        style="font-size:15pt; font-weight:100; text-align: left;vertical-align:middle;">
                                                        <![CDATA[}]]></td>
                                                    <td colspan="14">
                                                        <span>
                                                            <xsl:for-each
                                                                    select="*[local-name() = 'CRegListList']/*[local-name() = 'CRegItem']">
                                                                <xsl:value-of select="@CRegId"/>
                                                                <br/>
                                                            </xsl:for-each>
                                                        </span>
                                                    </td>
                                                </tr>
                                            </xsl:when>
                                        </xsl:choose>

                                        <xsl:choose>
                                            <xsl:when test="@TranType">
                                                <tr>
                                                    <td colspan="22" style="height:10pt"><![CDATA[ ]]></td>
                                                </tr>
                                                <tr>
                                                    <td colspan="6" style="vertical-align:middle;">Transaction type</td>
                                                    <td colspan="2"
                                                        style="font-size:15pt; font-weight:100; text-align: left;vertical-align:middle;"></td>
                                                    <td colspan="14">
                                                        <span>
                                                            <xsl:value-of select="@TranType"/>
                                                        </span>
                                                    </td>
                                                </tr>
                                            </xsl:when>
                                        </xsl:choose>

                                    </table>
                                </xsl:when>
                                <xsl:when test="@TransKind = '09'">
                                    <xsl:variable name="documentCode">0401108</xsl:variable>
                                    <xsl:variable name="NCCBank">НКО НКЦ (АО)</xsl:variable>
                                    <table border="0" cellpadding="0" cellspacing="0" width="672"
                                           style='border-collapse: collapse;table-layout:fixed; width:504pt'>
                                        <col class="xl65" width="219"
                                             style='mso-width-source:userset;mso-width-alt:8030; width:164pt'/>
                                        <col class="xl65" width="136"
                                             style='mso-width-source:userset;mso-width-alt:4994; width:102pt'/>
                                        <col class="xl65" width="56"
                                             style='mso-width-source:userset;mso-width-alt:2056; width:42pt'/>
                                        <col class="xl67" width="67"
                                             style='mso-width-source:userset;mso-width-alt:2468; width:50.4pt'/>
                                        <col class="xl65" width="67"
                                             style='mso-width-source:userset;mso-width-alt:2468; width:50.4pt'/>
                                        <col class="xl65" width="37"
                                             style='mso-width-source:userset;mso-width-alt:1370; width:28pt'/>
                                        <col class="xl65" width="90"
                                             style='mso-width-source:userset;mso-width-alt:3290; width:67.2pt'/>
                                        <tr style='mso-height-source:userset;height:10pt'>
                                            <td colspan="7"/>
                                        </tr>
                                        <tr height="40" style='mso-height-source:userset; height:30pt'>
                                            <td colspan="5"/>
                                            <td colspan="2" class='xl66' style="padding:5pt;">
                                                OKUD code of form
                                            </td>
                                        </tr>
                                        <tr height="40" style='mso-height-source:userset; height:30pt'>
                                            <td colspan="5"/>
                                            <td colspan="2" class='xl66' style="padding:5pt;">
                                                <span>
                                                    <xsl:value-of select="$documentCode"/>
                                                </span>
                                            </td>
                                        </tr>
                                        <tr height="20" style='mso-height-source:userset;height:15.0pt'>
                                            <td colspan="2" height="20" class="xl65" width="128"
                                                style='height:15.0pt; width:96pt;'>
                                                <span>
                                                    <xsl:value-of select="$NCCBank"/>
                                                </span>
                                            </td>
                                            <td colspan="5"/>
                                        </tr>
                                        <tr height="13" style='mso-height-source:userset;height:9.75pt'>
                                            <td colspan="2" height="13" class="xl73"
                                                style='height:9.75pt; text-align:left;'>Drawer of a document
                                            </td>
                                            <td colspan="5"/>
                                        </tr>
                                        <tr height="25" style='mso-height-source:userset;height:20pt'>
                                            <td height="45" class="xl74" style='height:34.55pt; white-space:nowrap;'>
                                                TRANSACTION MEMO
                                            </td>
                                            <td class="xl75">
                                                <span>
                                                    <xsl:value-of select="@Trans"/>
                                                </span>
                                            </td>
                                            <td class="xl65"/>
                                            <td colspan="2" class="xl67">
                                                <span>
                                                    <xsl:call-template name="format-date">
                                                        <xsl:with-param name="yyyy-mm-dd" select="@TransDate"/>
                                                    </xsl:call-template>
                                                </span>
                                            </td>
                                            <td class="xl65"/>
                                            <td class="xl65"/>
                                        </tr>
                                        <tr height="25" style='mso-height-source:userset;height:20pt'>
                                            <td height="45" class="xl74" style='height:34.55pt'></td>
                                            <td class="xl73"><![CDATA[ ]]></td>
                                            <td class="xl65"/>
                                            <td colspan="2" class="xl73"><![CDATA[ ]]></td>
                                            <td class="xl65"/>
                                            <td class="xl65"/>
                                        </tr>
                                        <tr height="32" style='mso-height-source:userset;height:24pt'>
                                            <td class="xl77">Account details</td>
                                            <td colspan="2" class="xl77">Debit</td>
                                            <td colspan="4" class="xl77">Amount by digit</td>
                                        </tr>
                                        <tr height="32">
                                            <td class="xl77">
                                                <span>
                                                    <xsl:value-of
                                                            select="*[local-name() = 'AccountRU']/*[local-name() = 'Payer']/@Name"/>
                                                </span>
                                            </td>
                                            <td colspan="2" class="xl77">
                                                <span>
                                                    <xsl:value-of
                                                            select="*[local-name() = 'AccountRU']/*[local-name() = 'Payer']/@PersonalAcc"/>
                                                </span>
                                            </td>
                                            <td colspan="2" rowspan="3" class="xl97">
                                                <span>
                                                    <xsl:call-template name="format-amount">
                                                        <xsl:with-param name="amount" select="@Sum"/>
                                                        <xsl:with-param name="asset" select="@Asset"/>
                                                        <xsl:with-param name="scale" select="2"/>
                                                    </xsl:call-template>
                                                </span>
                                            </td>
                                            <td colspan="2" rowspan="3" class="xl77"></td>
                                        </tr>
                                        <tr height="32" style='mso-height-source:userset;height:24pt'>
                                            <td class="xl77">Account details</td>
                                            <td colspan="2" class="xl77">Credit</td>
                                        </tr>
                                        <tr height="32">
                                            <td class="xl77">
                                                <span>
                                                    <xsl:value-of
                                                            select="*[local-name() = 'AccountRU']/*[local-name() = 'Payee']/@Name"/>
                                                </span>
                                            </td>
                                            <td colspan="2" class="xl77">
                                                <span>
                                                    <xsl:value-of
                                                            select="*[local-name() = 'AccountRU']/*[local-name() = 'Payee']/@PersonalAcc"/>
                                                </span>
                                            </td>
                                        </tr>
                                        <tr height="60" style='mso-height-source:userset; height:45pt'>
                                            <td colspan="4" rowspan="3" class="xl97">Amount expressed in words
                                                <br/>
                                                <span>
                                                    <xsl:call-template name="in-words">
                                                        <xsl:with-param name="value" select="$Sum"/>
                                                    </xsl:call-template>
                                                </span>
                                            </td>
                                            <td colspan="2" class="xl97">File reference</td>
                                            <td class="xl97">
                                                <span>
                                                    <xsl:value-of select="@TransKind"/>
                                                </span>
                                            </td>
                                        </tr>
                                        <tr style='mso-height-source:userset;height:24pt '>
                                            <td colspan="2" class="xl97"/>
                                            <td class="xl97"/>
                                        </tr>
                                        <tr style='mso-height-source:userset;height:24pt '>
                                            <td colspan="2" class="xl97"/>
                                            <td class="xl97"/>
                                        </tr>
                                        <tr height="20" style='mso-height-source:userset; height:12pt'>
                                            <td colspan="7" height="16">Operation subject, document name, number and
                                                date, on the basis of which is composed memo
                                                <br/>
                                            </td>
                                        </tr>
                                        <tr height="39" style='mso-height-source:userset;height:30pt'>
                                            <td colspan="7" class="xl71">
                                                <span>
                                                    <xsl:value-of select="@Details"/>
                                                </span>
                                            </td>
                                        </tr>
                                        <tr height="52" style='mso-height-source:userset;height:32pt'>
                                            <td colspan="7" height="16" class="xl71">Signature mark</td>
                                        </tr>
                                        <tr height="26" style='mso-height-source:userset;height:20pt'>
                                            <td colspan="7" height="16" style='height:40pt'>Application:
                                                _________________ documents of ________ pages
                                            </td>
                                        </tr>
                                        <tr>
                                            <td colspan="7" style="height:35pt"><![CDATA[ ]]></td>
                                        </tr>
                                        <xsl:choose>
                                            <xsl:when test="*[local-name() = 'CRegListList']">
                                                <tr>
                                                    <td style="vertical-align:middle;">Clearing Register’s Code (1 or
                                                        >1)<br/>2nd, 3rd level Settlement Code
                                                    </td>
                                                    <td style="font-size:15pt; font-weight:100; text-align: left;vertical-align:middle;">
                                                        <![CDATA[}]]></td>
                                                    <td colspan="5">
                                                        <span>
                                                            <xsl:for-each
                                                                    select="*[local-name() = 'CRegListList']/*[local-name() = 'CRegItem']">
                                                                <xsl:value-of select="@CRegId"/>
                                                                <br/>
                                                            </xsl:for-each>
                                                        </span>
                                                    </td>
                                                </tr>
                                            </xsl:when>
                                        </xsl:choose>
                                        <xsl:choose>
                                            <xsl:when test="@TranType">
                                                <tr>
                                                    <td colspan="7" style="height:10pt"><![CDATA[ ]]></td>
                                                </tr>
                                                <tr>
                                                    <td style="vertical-align:middle;">Transaction type</td>
                                                    <td style="font-size:15pt; font-weight:100; text-align: left;vertical-align:middle;"></td>
                                                    <td colspan="5">
                                                        <span>
                                                            <xsl:value-of select="@TranType"/>
                                                        </span>
                                                    </td>
                                                </tr>
                                            </xsl:when>
                                        </xsl:choose>

                                    </table>
                                </xsl:when>
                            </xsl:choose>
                        </xsl:when>
                        <xsl:otherwise>
                            <div>
                                <table class="notice1" cellpadding="4" style='width:504pt'>
                                    <col width="50%"/>
                                    <col width="50%"/>
                                    <thead>
                                        <tr>
                                            <th>Field</th>
                                            <th>Data</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <xsl:choose>
                                            <xsl:when test="@PayRef">
                                                <tr>
                                                    <td>Transaction Reference Number</td>
                                                    <td>
                                                        <xsl:value-of select="@PayRef"/>
                                                    </td>
                                                </tr>
                                            </xsl:when>
                                        </xsl:choose>
                                        <xsl:choose>
                                            <xsl:when test="@RelRef">
                                                <tr>
                                                    <td>Pay number</td>
                                                    <td>
                                                        <xsl:value-of select="@RelRef"/>
                                                    </td>
                                                </tr>
                                            </xsl:when>
                                        </xsl:choose>
                                        <xsl:choose>
                                            <xsl:when test="@OperKind">
                                                <tr>
                                                    <td>Bank Operation Code</td>
                                                    <td>
                                                        <xsl:value-of select="@OperKind"/>
                                                    </td>
                                                </tr>
                                            </xsl:when>
                                        </xsl:choose>
                                        <xsl:choose>
                                            <xsl:when test="@TranType">
                                                <tr>
                                                    <td>Transaction type</td>
                                                    <td>
                                                        <xsl:value-of select="@TranType"/>
                                                    </td>
                                                </tr>
                                            </xsl:when>
                                        </xsl:choose>
                                        <tr>
                                            <td>Account</td>
                                            <td>
                                                <xsl:value-of select="Account"/>
                                            </td>
                                        </tr>
                                        <xsl:choose>
                                            <xsl:when test="@TransDate">
                                                <tr>
                                                    <td>Value Date</td>
                                                    <td>
                                                        <xsl:call-template name="format-date">
                                                            <xsl:with-param name="yyyy-mm-dd" select="@TransDate"/>
                                                        </xsl:call-template>
                                                    </td>
                                                </tr>
                                            </xsl:when>
                                        </xsl:choose>
                                        <xsl:choose>
                                            <xsl:when test="@Asset">
                                                <tr>
                                                    <td>Currency</td>
                                                    <td>
                                                        <xsl:value-of select="@Asset"/>
                                                    </td>
                                                </tr>
                                            </xsl:when>
                                        </xsl:choose>
                                        <xsl:choose>
                                            <xsl:when test="@DC='D'">
                                                <tr>
                                                    <td>Debit</td>
                                                    <td>
                                                        <xsl:call-template name="format-amount">
                                                            <xsl:with-param name="amount" select="@Sum"/>
                                                            <xsl:with-param name="asset" select="@Asset"/>
                                                            <xsl:with-param name="scale" select="@Scale"/>
                                                        </xsl:call-template>
                                                    </td>
                                                </tr>
                                            </xsl:when>
                                        </xsl:choose>
                                        <xsl:choose>
                                            <xsl:when test="@DC='C'">
                                                <tr>
                                                    <td>Credit</td>
                                                    <td>
                                                        <xsl:call-template name="format-amount">
                                                            <xsl:with-param name="amount" select="@Sum"/>
                                                            <xsl:with-param name="asset" select="@Asset"/>
                                                            <xsl:with-param name="scale" select="@Scale"/>
                                                        </xsl:call-template>
                                                    </td>
                                                </tr>
                                            </xsl:when>
                                        </xsl:choose>

                                        <xsl:choose>
                                            <xsl:when
                                                    test="*[local-name() = 'AccountSWIFT']/*[local-name() = 'OrderingParty']">
                                                <tr>
                                                    <td>Payer</td>
                                                    <td>
                                                        <xsl:for-each
                                                                select="*[local-name() = 'AccountSWIFT']/*[local-name() = 'OrderingParty']">
                                                            <xsl:choose>
                                                                <xsl:when test="@Account">
                                                                    <xsl:value-of select="@Account"/>
                                                                    <br/>
                                                                </xsl:when>
                                                            </xsl:choose>
                                                            <xsl:choose>
                                                                <xsl:when test="@BIC">
                                                                    <xsl:value-of select="@BIC"/>
                                                                    <br/>
                                                                </xsl:when>
                                                            </xsl:choose>
                                                            <xsl:for-each select="*[local-name() = 'NameAddr']">
                                                                <xsl:value-of select="text()"/>
                                                            </xsl:for-each>
                                                        </xsl:for-each>
                                                    </td>
                                                </tr>
                                            </xsl:when>
                                        </xsl:choose>
                                        <xsl:choose>
                                            <xsl:when
                                                    test="*[local-name() = 'AccountSWIFT']/*[local-name() = 'IntermediaryBank']">
                                                <tr>
                                                    <td>Correspondent Bank</td>
                                                    <td>
                                                        <xsl:for-each
                                                                select="*[local-name() = 'AccountSWIFT']/*[local-name() = 'IntermediaryBank']">
                                                            <xsl:choose>
                                                                <xsl:when test="@Account">
                                                                    <xsl:value-of select="@Account"/>
                                                                    <br/>
                                                                </xsl:when>
                                                            </xsl:choose>
                                                            <xsl:choose>
                                                                <xsl:when test="@BIC">
                                                                    <xsl:value-of select="@BIC"/>
                                                                    <br/>
                                                                </xsl:when>
                                                            </xsl:choose>
                                                            <xsl:for-each select="*[local-name() = 'NameAddr']">
                                                                <xsl:value-of select="text()"/>
                                                            </xsl:for-each>
                                                        </xsl:for-each>
                                                    </td>
                                                </tr>
                                            </xsl:when>
                                        </xsl:choose>
                                        <xsl:choose>
                                            <xsl:when
                                                    test="*[local-name() = 'AccountSWIFT']/*[local-name() = 'BeneficiaryBank']">
                                                <tr>
                                                    <td>Beneficiary bank</td>
                                                    <td>
                                                        <xsl:for-each
                                                                select="*[local-name() = 'AccountSWIFT']/*[local-name() = 'BeneficiaryBank']">
                                                            <xsl:choose>
                                                                <xsl:when test="@Account">
                                                                    <xsl:value-of select="@Account"/>
                                                                    <br/>
                                                                </xsl:when>
                                                            </xsl:choose>
                                                            <xsl:choose>
                                                                <xsl:when test="@BIC">
                                                                    <xsl:value-of select="@BIC"/>
                                                                    <br/>
                                                                </xsl:when>
                                                            </xsl:choose>
                                                            <xsl:for-each select="*[local-name() = 'NameAddr']">
                                                                <xsl:value-of select="text()"/>
                                                            </xsl:for-each>
                                                        </xsl:for-each>
                                                    </td>
                                                </tr>
                                            </xsl:when>

                                        </xsl:choose>
                                        <xsl:choose>
                                            <xsl:when
                                                    test="*[local-name() = 'AccountSWIFT']/*[local-name() = 'Beneficiary']">
                                                <tr>
                                                    <td>Beneficiary</td>
                                                    <td>
                                                        <xsl:for-each
                                                                select="*[local-name() = 'AccountSWIFT']/*[local-name() = 'Beneficiary']">
                                                            <xsl:choose>
                                                                <xsl:when test="@Account">
                                                                    <xsl:value-of select="@Account"/>
                                                                    <br/>
                                                                </xsl:when>
                                                            </xsl:choose>
                                                            <xsl:choose>
                                                                <xsl:when test="@BIC">
                                                                    <xsl:value-of select="@BIC"/>
                                                                    <br/>
                                                                </xsl:when>
                                                            </xsl:choose>
                                                            <xsl:for-each select="*[local-name() = 'NameAddr']">
                                                                <xsl:value-of select="text()"/>
                                                            </xsl:for-each>
                                                        </xsl:for-each>
                                                    </td>
                                                </tr>
                                            </xsl:when>
                                        </xsl:choose>

                                        <xsl:choose>
                                            <xsl:when test="@PURPOSE_PAYMENT">
                                                <tr>
                                                    <td>Payment purpose</td>
                                                    <td>
                                                        <xsl:call-template name="replace-str">
                                                            <xsl:with-param name="string" select="@Details"/>
                                                            <xsl:with-param name="char" select="'&#47;&#47;'"/>
                                                            <xsl:with-param name="replacement">
                                                                <xsl:element name="br"/>
                                                                <xsl:text>&#47;&#47;</xsl:text>
                                                            </xsl:with-param>
                                                        </xsl:call-template>
                                                    </td>
                                                </tr>
                                            </xsl:when>
                                        </xsl:choose>
                                        <xsl:choose>
                                            <xsl:when test="*[local-name() = 'CRegListList']">
                                                <tr>
                                                    <td>Clearing Register’s Code</td>
                                                    <td>

                                                        <xsl:for-each
                                                                select="*[local-name() = 'CRegListList']/*[local-name() = 'CRegItem']">
                                                            <xsl:value-of select="@CRegId"/>
                                                            <br/>
                                                        </xsl:for-each>

                                                    </td>
                                                </tr>
                                            </xsl:when>
                                        </xsl:choose>
										<xsl:choose>
											<xsl:when test="@UETR">
												<tr>
													<td>UETR Code</td>
													<td>
														<xsl:value-of select="@UETR"/>
													</td>
												</tr>
											</xsl:when>
										</xsl:choose>
										<xsl:choose>
											<xsl:when test="@TransportSystem">
												<tr>
													<td>Transport System</td>
													<td>
														<xsl:value-of select="@TransportSystem"/>
													</td>
												</tr>
											</xsl:when>
										</xsl:choose>
                                    </tbody>
                                </table>
                            </div>
                        </xsl:otherwise>
                    </xsl:choose>

                </xsl:for-each>
            </body>
        </html>
    </xsl:template>
</xsl:stylesheet>
