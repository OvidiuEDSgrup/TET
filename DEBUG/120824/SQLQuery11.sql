--declare @p2 xml
--set @p2=convert(xml,N'<date><document aplicatie="PV" tip="PV" casamarcat="83" data="08/24/2012" inXML="0" UID="0AECBE48-BDF4-904C-5A66-59161C4D1DC4" categoriePret="4" tert="1550829270616" comanda="9810302" tipdoc="AC" numarDoc="4" pentruValidare="1" ora="1746" totaldocument="2057.08" totalincasari="2057.08" descarcarePrioritara="0"><pozitii><row tert="1550829270616" contract="9810302" data="22/08/2012" cod="10120019" denumire="TRUST-�eav� Pvc Cu Garnitur� 110/1000" cantitate="1" um="BUC" pretcatalog="11.19" cotatva="24" discount="0" yso_stocinstalatori="1" yso_pretcomlivr="11.18480" yso_disccomlivr="0.00" yso_gestpredte="211      " explicatii="NECHITA IOAN-9810302-22/08/2012" comanda_asis="1550829270616" pret="11.19" valoare="11.19" stocMaxim="1.000" gestiune="700" tipLinie="Produs" o_pretcatalog="11.19" tip="21" observatii="1 BUC x 11.19" valoarefaradiscount="11.19" tva="2.17" pretftva="9.02" valftva="9.02" nrlinie="1"/><row tert="1550829270616" contract="9810302" data="22/08/2012" cod="TR0144" denumire="TRUST-Teu 130 1/2 ZN" cantitate="2" um="BUC" pretcatalog="2.03" cotatva="24" discount="0" yso_stocinstalatori="1" yso_pretcomlivr="2.03360" yso_disccomlivr="0.00" yso_gestpredte="211      " explicatii="NECHITA IOAN-9810302-22/08/2012" comanda_asis="1550829270616" pret="2.03" valoare="4.06" stocMaxim="2.000" gestiune="700" tipLinie="Produs" o_pretcatalog="2.03" tip="21" observatii="2 BUC x 2.03" valoarefaradiscount="4.06" tva="0.79" pretftva="1.64" valftva="3.27" nrlinie="2"/><row tert="1550829270616" contract="9810302" data="22/08/2012" cod="EVP-RC11/4/12FDS-11" denumire="TRUST-Set accesorii calorifer cu console 11piese" cantitate="2" um="BUC" pretcatalog="21.76" cotatva="24" discount="0" yso_stocinstalatori="1" yso_pretcomlivr="21.76200" yso_disccomlivr="0.00" yso_gestpredte="211      " explicatii="NECHITA IOAN-9810302-22/08/2012" comanda_asis="1550829270616" pret="21.76" valoare="43.52" stocMaxim="2.000" gestiune="700" tipLinie="Produs" o_pretcatalog="21.76" tip="21" observatii="2 BUC x 21.76" valoarefaradiscount="43.52" tva="8.42" pretftva="17.55" valftva="35.10" nrlinie="3"/><row tert="1550829270616" contract="9810302" data="22/08/2012" cod="BST-RFTM12" denumire="TRUST-Robinet sferic BESTEN cu fluture TM 1/2&quot;" cantitate="1" um="BUC" pretcatalog="11.78" cotatva="24" discount="0" yso_stocinstalatori="1" yso_pretcomlivr="11.78000" yso_disccomlivr="0.00" yso_gestpredte="211      " explicatii="NECHITA IOAN-9810302-22/08/2012" comanda_asis="1550829270616" pret="11.78" valoare="11.78" stocMaxim="1.000" gestiune="700" tipLinie="Produs" o_pretcatalog="11.78" tip="21" observatii="1 BUC x 11.78" valoarefaradiscount="11.78" tva="2.28" pretftva="9.50" valftva="9.50" nrlinie="4"/><row tert="1550829270616" contract="9810302" data="22/08/2012" cod="RB-HMF34" denumire="TRUST-Robinet cu holender 3/4&quot; FI-FE" cantitate="2" um="BUC" pretcatalog="26.04" cotatva="24" discount="0" yso_stocinstalatori="1" yso_pretcomlivr="26.04000" yso_disccomlivr="0.00" yso_gestpredte="211      " explicatii="NECHITA IOAN-9810302-22/08/2012" comanda_asis="1550829270616" pret="26.04" valoare="52.08" stocMaxim="2.000" gestiune="700" tipLinie="Produs" o_pretcatalog="26.04" tip="21" observatii="2 BUC x 26.04" valoarefaradiscount="52.08" tva="10.08" pretftva="21.00" valftva="42.00" nrlinie="5"/><row tert="1550829270616" contract="9810302" data="22/08/2012" cod="RB-HMF12" denumire="TRUST-Robinet cu holender 1/2&quot; FI-FE" cantitate="2" um="BUC" pretcatalog="15.81" cotatva="24" discount="0" yso_stocinstalatori="1" yso_pretcomlivr="15.81000" yso_disccomlivr="0.00" yso_gestpredte="211      " explicatii="NECHITA IOAN-9810302-22/08/2012" comanda_asis="1550829270616" pret="15.81" valoare="31.62" stocMaxim="2.000" gestiune="700" tipLinie="Produs" o_pretcatalog="15.81" tip="21" observatii="2 BUC x 15.81" valoarefaradiscount="31.62" tva="6.12" pretftva="12.75" valftva="25.50" nrlinie="6"/><row tert="1550829270616" contract="9810302" data="22/08/2012" cod="TR0074" denumire="TRUST-Niplu 280 1/2 ZN" cantitate="2" um="BUC" pretcatalog="1.29" cotatva="24" discount="0" yso_stocinstalatori="1" yso_pretcomlivr="1.28960" yso_disccomlivr="0.00" yso_gestpredte="211      " explicatii="NECHITA IOAN-9810302-22/08/2012" comanda_asis="1550829270616" pret="1.29" valoare="2.58" stocMaxim="2.000" gestiune="700" tipLinie="Produs" o_pretcatalog="1.29" tip="21" observatii="2 BUC x 1.29" valoarefaradiscount="2.58" tva="0.50" pretftva="1.04" valftva="2.08" nrlinie="7"/><row tert="1550829270616" contract="9810302" data="22/08/2012" cod="RADALN" denumire="TRUST-Niplu 1� pentru radiatoare aluminiu" cantitate="2" um="BUC" pretcatalog="2.48" cotatva="24" discount="0" yso_stocinstalatori="1" yso_pretcomlivr="2.48000" yso_disccomlivr="0.00" yso_gestpredte="211      " explicatii="NECHITA IOAN-9810302-22/08/2012" comanda_asis="1550829270616" pret="2.48" valoare="4.96" stocMaxim="2.000" gestiune="700" tipLinie="Produs" o_pretcatalog="2.48" tip="21" observatii="2 BUC x 2.48" valoarefaradiscount="4.96" tva="0.96" pretftva="2.00" valftva="4.00" nrlinie="8"/><row tert="1550829270616" contract="9810302" data="22/08/2012" cod="RADALG" denumire="TRUST-Garnitura 1� pentru radiatoare aluminiu" cantitate="4" um="BUC" pretcatalog="1.98" cotatva="24" discount="0" yso_stocinstalatori="1" yso_pretcomlivr="1.98400" yso_disccomlivr="0.00" yso_gestpredte="211      " explicatii="NECHITA IOAN-9810302-22/08/2012" comanda_asis="1550829270616" pret="1.98" valoare="7.92" stocMaxim="4.000" gestiune="700" tipLinie="Produs" o_pretcatalog="1.98" tip="21" observatii="4 BUC x 1.98" valoarefaradiscount="7.92" tva="1.53" pretftva="1.60" valftva="6.39" nrlinie="9"/><row tert="1550829270616" contract="9810302" data="22/08/2012" cod="PPR-FY25" denumire="TRUST-FILTRU Y PPR 25" cantitate="1" um="BUC" pretcatalog="8.98" cotatva="24" discount="0" yso_stocinstalatori="1" yso_pretcomlivr="8.97760" yso_disccomlivr="0.00" yso_gestpredte="211      " explicatii="NECHITA IOAN-9810302-22/08/2012" comanda_asis="1550829270616" pret="8.98" valoare="8.98" stocMaxim="1.000" gestiune="700" tipLinie="Produs" o_pretcatalog="8.98" tip="21" observatii="1 BUC x 8.98" valoarefaradiscount="8.98" tva="1.74" pretftva="7.24" valftva="7.24" nrlinie="10"/><row tert="1550829270616" contract="9810302" data="22/08/2012" cod="MA-FM12" denumire="TRUST-FILTRU MAGNETIC PENTRU APA 1/2 FI" cantitate="1" um="BUC" pretcatalog="36.17" cotatva="24" discount="0" yso_stocinstalatori="1" yso_pretcomlivr="36.17080" yso_disccomlivr="0.00" yso_gestpredte="211      " explicatii="NECHITA IOAN-9810302-22/08/2012" comanda_asis="1550829270616" pret="36.17" valoare="36.17" stocMaxim="1.000" gestiune="700" tipLinie="Produs" o_pretcatalog="36.17" tip="21" observatii="1 BUC x 36.17" valoarefaradiscount="36.17" tva="7.00" pretftva="29.17" valftva="29.17" nrlinie="11"/><row tert="1550829270616" contract="9810302" data="22/08/2012" cod="RADAL60" denumire="TRUST-Element radiator aluminiu TOP 60R" cantitate="30" um="BUC" pretcatalog="44.64" cotatva="24" discount="0" yso_stocinstalatori="1" yso_pretcomlivr="36.35680" yso_disccomlivr="0.00" yso_gestpredte="211      " explicatii="NECHITA IOAN-9810302-22/08/2012" comanda_asis="1550829270616" pret="44.64" valoare="1339.2" stocMaxim="30.000" gestiune="700" tipLinie="Produs" o_pretcatalog="44.64" tip="21" observatii="30 BUC x 44.64" valoarefaradiscount="1339.2" tva="259.20" pretftva="36.00" valftva="1080.00" nrlinie="12"/><row tert="1550829270616" contract="9810302" data="22/08/2012" cod="EFC-DM12" denumire="TRUST-Dop alama 1/2&quot;&quot; FE" cantitate="1" um="BUC" pretcatalog="1.57" cotatva="24" discount="0" yso_stocinstalatori="1" yso_pretcomlivr="1.57480" yso_disccomlivr="0.00" yso_gestpredte="211      " explicatii="NECHITA IOAN-9810302-22/08/2012" comanda_asis="1550829270616" pret="1.57" valoare="1.57" stocMaxim="1.000" gestiune="700" tipLinie="Produs" o_pretcatalog="1.57" tip="21" observatii="1 BUC x 1.57" valoarefaradiscount="1.57" tva="0.30" pretftva="1.27" valftva="1.27" nrlinie="13"/><row tert="1550829270616" contract="9810302" data="22/08/2012" cod="10310033" denumire="TRUST-Diblu Fi 8 Cu Surub" cantitate="5" um="SET" pretcatalog="3.26" cotatva="24" discount="0" yso_stocinstalatori="1" yso_pretcomlivr="3.26120" yso_disccomlivr="0.00" yso_gestpredte="211      " explicatii="NECHITA IOAN-9810302-22/08/2012" comanda_asis="1550829270616" pret="3.26" valoare="16.3" stocMaxim="5.000" gestiune="700" tipLinie="Produs" o_pretcatalog="3.26" tip="21" observatii="5 SET x 3.26" valoarefaradiscount="16.3" tva="3.15" pretftva="2.63" valftva="13.15" nrlinie="14"/><row tert="1550829270616" contract="9810302" data="22/08/2012" cod="10410000" denumire="TRUST-Canepa 50 G" cantitate="1" um="BUC" pretcatalog="2.15" cotatva="24" discount="0" yso_stocinstalatori="1" yso_pretcomlivr="2.14520" yso_disccomlivr="0.00" yso_gestpredte="211      " explicatii="NECHITA IOAN-9810302-22/08/2012" comanda_asis="1550829270616" pret="2.15" valoare="2.15" stocMaxim="1.000" gestiune="700" tipLinie="Produs" o_pretcatalog="2.15" tip="21" observatii="1 BUC x 2.15" valoarefaradiscount="2.15" tva="0.42" pretftva="1.73" valftva="1.73" nrlinie="15"/><row tert="1550829270616" contract="9810302" data="22/08/2012" cod="RB-E12" denumire="TRUST- Robinet de golire 1/2&quot;&quot;" cantitate="1" um="BUC" pretcatalog="15.49" cotatva="24" discount="0" yso_stocinstalatori="1" yso_pretcomlivr="15.48760" yso_disccomlivr="0.00" yso_gestpredte="211      " explicatii="NECHITA IOAN-9810302-22/08/2012" comanda_asis="1550829270616" pret="15.49" valoare="15.49" stocMaxim="1.000" gestiune="700" tipLinie="Produs" o_pretcatalog="15.49" tip="21" observatii="1 BUC x 15.49" valoarefaradiscount="15.49" tva="3.00" pretftva="12.49" valftva="12.49" nrlinie="16"/><row tert="1550829270616" contract="9810302" data="22/08/2012" cod="4300902520121" denumire="HK-Teu redus 25x20x25" cantitate="2" um="BUC" pretcatalog="0.93" cotatva="24" discount="0" yso_stocinstalatori="1" yso_pretcomlivr="0.93000" yso_disccomlivr="0.00" yso_gestpredte="211      " explicatii="NECHITA IOAN-9810302-22/08/2012" comanda_asis="1550829270616" pret="0.93" valoare="1.86" stocMaxim="2.000" gestiune="700" tipLinie="Produs" o_pretcatalog="0.93" tip="21" observatii="2 BUC x 0.93" valoarefaradiscount="1.86" tva="0.36" pretftva="0.75" valftva="1.50" nrlinie="17"/><row tert="1550829270616" contract="9810302" data="22/08/2012" cod="4300902508121" denumire="HK-Teu egal 25x25x25" cantitate="1" um="BUC" pretcatalog="0.67" cotatva="24" discount="0" yso_stocinstalatori="1" yso_pretcomlivr="0.66960" yso_disccomlivr="0.00" yso_gestpredte="211      " explicatii="NECHITA IOAN-9810302-22/08/2012" comanda_asis="1550829270616" pret="0.67" valoare="0.67" stocMaxim="1.000" gestiune="700" tipLinie="Produs" o_pretcatalog="0.67" tip="21" observatii="1 BUC x 0.67" valoarefaradiscount="0.67" tva="0.13" pretftva="0.54" valftva="0.54" nrlinie="18"/><row tert="1550829270616" contract="9810302" data="22/08/2012" cod="4300902010021" denumire="HK-Teu 20x1/2&quot;&quot; Mx20" cantitate="1" um="BUC" pretcatalog="3.76" cotatva="24" discount="0" yso_stocinstalatori="1" yso_pretcomlivr="3.75720" yso_disccomlivr="0.00" yso_gestpredte="211      " explicatii="NECHITA IOAN-9810302-22/08/2012" comanda_asis="1550829270616" pret="3.76" valoare="3.76" stocMaxim="1.000" gestiune="700" tipLinie="Produs" o_pretcatalog="3.76" tip="21" observatii="1 BUC x 3.76" valoarefaradiscount="3.76" tva="0.73" pretftva="3.03" valftva="3.03" nrlinie="19"/><row tert="1550829270616" contract="9810302" data="22/08/2012" cod="4200002500221" denumire="HK-Teava PPR fibra compozita DN25, bara 4 m" cantitate="8" um="ML" pretcatalog="5.63" cotatva="24" discount="0" yso_stocinstalatori="1" yso_pretcomlivr="5.62960" yso_disccomlivr="0.00" yso_gestpredte="211      " explicatii="NECHITA IOAN-9810302-22/08/2012" comanda_asis="1550829270616" pret="5.63" valoare="45.04" stocMaxim="8.000" gestiune="700" tipLinie="Produs" o_pretcatalog="5.63" tip="21" observatii="8 ML x 5.63" valoarefaradiscount="45.04" tva="8.72" pretftva="4.54" valftva="36.32" nrlinie="20"/><row tert="1550829270616" contract="9810302" data="22/08/2012" cod="4200002000121" denumire="HK-Teava PPR fibra compozita DN20, bara 4 m" cantitate="48" um="ML" pretcatalog="4.02" cotatva="24" discount="0" yso_stocinstalatori="1" yso_pretcomlivr="4.01760" yso_disccomlivr="0.00" yso_gestpredte="211      " explicatii="NECHITA IOAN-9810302-22/08/2012" comanda_asis="1550829270616" pret="4.02" valoare="192.96" stocMaxim="48.000" gestiune="700" tipLinie="Produs" o_pretcatalog="4.02" tip="21" observatii="48 ML x 4.02" valoarefaradiscount="192.96" tva="37.35" pretftva="3.24" valftva="155.61" nrlinie="21"/><row tert="1550829270616" contract="9810302" data="22/08/2012" cod="4300402510021" denumire="HK-Reductie TM 25x20" cantitate="4" um="BUC" pretcatalog="0.4" cotatva="24" discount="0" yso_stocinstalatori="1" yso_pretcomlivr="0.39680" yso_disccomlivr="0.00" yso_gestpredte="211      " explicatii="NECHITA IOAN-9810302-22/08/2012" comanda_asis="1550829270616" pret="0.4" valoare="1.6" stocMaxim="4.000" gestiune="700" tipLinie="Produs" o_pretcatalog="0.40" tip="21" observatii="4 BUC x 0.4" valoarefaradiscount="1.6" tva="0.31" pretftva="0.32" valftva="1.29" nrlinie="22"/><row tert="1550829270616" contract="9810302" data="22/08/2012" cod="4300702530321" denumire="HK-Racord drept 25x3/4&quot;&quot; M" cantitate="2" um="BUC" pretcatalog="4.3" cotatva="24" discount="0" yso_stocinstalatori="1" yso_pretcomlivr="4.30280" yso_disccomlivr="0.00" yso_gestpredte="211      " explicatii="NECHITA IOAN-9810302-22/08/2012" comanda_asis="1550829270616" pret="4.3" valoare="8.6" stocMaxim="2.000" gestiune="700" tipLinie="Produs" o_pretcatalog="4.30" tip="21" observatii="2 BUC x 4.3" valoarefaradiscount="8.6" tva="1.66" pretftva="3.47" valftva="6.94" nrlinie="23"/><row tert="1550829270616" contract="9810302" data="22/08/2012" cod="4300702032021" denumire="HK-Racord drept 20x1/2&quot;&quot; T" cantitate="7" um="BUC" pretcatalog="4.02" cotatva="24" discount="0" yso_stocinstalatori="1" yso_pretcomlivr="4.01760" yso_disccomlivr="0.00" yso_gestpredte="211      " explicatii="NECHITA IOAN-9810302-22/08/2012" comanda_asis="1550829270616" pret="4.02" valoare="28.14" stocMaxim="7.000" gestiune="700" tipLinie="Produs" o_pretcatalog="4.02" tip="21" observatii="7 BUC x 4.02" valoarefaradiscount="28.14" tva="5.45" pretftva="3.24" valftva="22.69" nrlinie="24"/><row tert="1550829270616" contract="9810302" data="22/08/2012" cod="4300702030021" denumire="HK-Racord drept 20x1/2&quot;&quot; M" cantitate="6" um="BUC" pretcatalog="3.09" cotatva="24" discount="0" yso_stocinstalatori="1" yso_pretcomlivr="3.08760" yso_disccomlivr="0.00" yso_gestpredte="211      " explicatii="NECHITA IOAN-9810302-22/08/2012" comanda_asis="1550829270616" pret="3.09" valoare="18.54" stocMaxim="6.000" gestiune="700" tipLinie="Produs" o_pretcatalog="3.09" tip="21" observatii="6 BUC x 3.09" valoarefaradiscount="18.54" tva="3.59" pretftva="2.49" valftva="14.95" nrlinie="25"/><row tert="1550829270616" contract="9810302" data="22/08/2012" cod="4300902004021" denumire="HK-Racord cu olandez complet 20x1/2&quot;&quot;T" cantitate="2" um="BUC" pretcatalog="9.36" cotatva="24" discount="0" yso_stocinstalatori="1" yso_pretcomlivr="9.36200" yso_disccomlivr="0.00" yso_gestpredte="211      " explicatii="NECHITA IOAN-9810302-22/08/2012" comanda_asis="1550829270616" pret="9.36" valoare="18.72" stocMaxim="2.000" gestiune="700" tipLinie="Produs" o_pretcatalog="9.36" tip="21" observatii="2 BUC x 9.36" valoarefaradiscount="18.72" tva="3.62" pretftva="7.55" valftva="15.10" nrlinie="26"/><row tert="1550829270616" contract="9810302" data="22/08/2012" cod="4300502520121" denumire="HK-Mufa dubla D25" cantitate="2" um="BUC" pretcatalog="0.53" cotatva="24" discount="0" yso_stocinstalatori="1" yso_pretcomlivr="0.53320" yso_disccomlivr="0.00" yso_gestpredte="211      " explicatii="NECHITA IOAN-9810302-22/08/2012" comanda_asis="1550829270616" pret="0.53" valoare="1.06" stocMaxim="2.000" gestiune="700" tipLinie="Produs" o_pretcatalog="0.53" tip="21" observatii="2 BUC x 0.53" valoarefaradiscount="1.06" tva="0.21" pretftva="0.43" valftva="0.85" nrlinie="27"/><row tert="1550829270616" contract="9810302" data="22/08/2012" cod="4300502020021" denumire="HK-Mufa dubla D20" cantitate="5" um="BUC" pretcatalog="0.27" cotatva="24" discount="0" yso_stocinstalatori="1" yso_pretcomlivr="0.27280" yso_disccomlivr="0.00" yso_gestpredte="211      " explicatii="NECHITA IOAN-9810302-22/08/2012" comanda_asis="1550829270616" pret="0.27" valoare="1.35" stocMaxim="5.000" gestiune="700" tipLinie="Produs" o_pretcatalog="0.27" tip="21" observatii="5 BUC x 0.27" valoarefaradiscount="1.35" tva="0.26" pretftva="0.22" valftva="1.09" nrlinie="28"/><row tert="1550829270616" contract="9810302" data="22/08/2012" cod="4300102500821" denumire="HK-Cot echer dublu 25x25" cantitate="10" um="BUC" pretcatalog="0.53" cotatva="24" discount="0" yso_stocinstalatori="1" yso_pretcomlivr="0.53320" yso_disccomlivr="0.00" yso_gestpredte="211      " explicatii="NECHITA IOAN-9810302-22/08/2012" comanda_asis="1550829270616" pret="0.53" valoare="5.3" stocMaxim="10.000" gestiune="700" tipLinie="Produs" o_pretcatalog="0.53" tip="21" observatii="10 BUC x 0.53" valoarefaradiscount="5.3" tva="1.03" pretftva="0.43" valftva="4.27" nrlinie="29"/><row tert="1550829270616" contract="9810302" data="22/08/2012" cod="4300102000721" denumire="HK-Cot echer dublu 20x20" cantitate="45" um="BUC" pretcatalog="0.4" cotatva="24" discount="0" yso_stocinstalatori="1" yso_pretcomlivr="0.39680" yso_disccomlivr="0.00" yso_gestpredte="211      " explicatii="NECHITA IOAN-9810302-22/08/2012" comanda_asis="1550829270616" pret="0.4" valoare="18" stocMaxim="45.000" gestiune="700" tipLinie="Produs" o_pretcatalog="0.40" tip="21" observatii="45 BUC x 0.4" valoarefaradiscount="18" tva="3.48" pretftva="0.32" valftva="14.52" nrlinie="30"/><row tert="1550829270616" contract="9810302" data="22/08/2012" cod="4300102500221" denumire="HK-Cot 45 dublu 25x25" cantitate="6" um="BUC" pretcatalog="0.81" cotatva="24" discount="0" yso_stocinstalatori="1" yso_pretcomlivr="0.80600" yso_disccomlivr="0.00" yso_gestpredte="211      " explicatii="NECHITA IOAN-9810302-22/08/2012" comanda_asis="1550829270616" pret="0.81" valoare="4.86" stocMaxim="6.000" gestiune="700" tipLinie="Produs" o_pretcatalog="0.81" tip="21" observatii="6 BUC x 0.81" valoarefaradiscount="4.86" tva="0.94" pretftva="0.65" valftva="3.92" nrlinie="31"/><row tert="1550829270616" contract="9810302" data="22/08/2012" cod="4300102000121" denumire="HK-Cot 45 dublu 20x20" cantitate="2" um="BUC" pretcatalog="0.67" cotatva="24" discount="0" yso_stocinstalatori="1" yso_pretcomlivr="0.66960" yso_disccomlivr="0.00" yso_gestpredte="211      " explicatii="NECHITA IOAN-9810302-22/08/2012" comanda_asis="1550829270616" pret="0.67" valoare="1.34" stocMaxim="2.000" gestiune="700" tipLinie="Produs" o_pretcatalog="0.67" tip="21" observatii="2 BUC x 0.67" valoarefaradiscount="1.34" tva="0.26" pretftva="0.54" valftva="1.08" nrlinie="32"/><row tert="1550829270616" contract="9810302" data="22/08/2012" cod="4300902525121" denumire="HK-Clema simpla D25" cantitate="10" um="BUC" pretcatalog="0.27" cotatva="24" discount="0" yso_stocinstalatori="1" yso_pretcomlivr="0.27280" yso_disccomlivr="0.00" yso_gestpredte="211      " explicatii="NECHITA IOAN-9810302-22/08/2012" comanda_asis="1550829270616" pret="0.27" valoare="2.7" stocMaxim="10.000" gestiune="700" tipLinie="Produs" o_pretcatalog="0.27" tip="21" observatii="10 BUC x 0.27" valoarefaradiscount="2.7" tva="0.52" pretftva="0.22" valftva="2.18" nrlinie="33"/><row tert="1550829270616" contract="9810302" data="22/08/2012" cod="4300902025021" denumire="HK-Clema simpla D20" cantitate="49" um="BUC" pretcatalog="0.27" cotatva="24" discount="0" yso_stocinstalatori="1" yso_pretcomlivr="0.27280" yso_disccomlivr="0.00" yso_gestpredte="211      " explicatii="NECHITA IOAN-9810302-22/08/2012" comanda_asis="1550829270616" pret="0.27" valoare="13.23" stocMaxim="49.000" gestiune="700" tipLinie="Produs" o_pretcatalog="0.27" tip="21" observatii="49 BUC x 0.27" valoarefaradiscount="13.23" tva="2.56" pretftva="0.22" valftva="10.67" nrlinie="34"/><row tert="1550829270616" contract="9810302" data="22/08/2012" cod="01350322" denumire="EM-Robinet echer retur 1/2&quot;&quot; ptr teava" cantitate="4" um="BUC" pretcatalog="24.18" cotatva="24" discount="0" yso_stocinstalatori="1" yso_pretcomlivr="24.18000" yso_disccomlivr="0.00" yso_gestpredte="211      " explicatii="NECHITA IOAN-9810302-22/08/2012" comanda_asis="1550829270616" pret="24.18" valoare="96.72" stocMaxim="4.000" gestiune="700" tipLinie="Produs" o_pretcatalog="24.18" tip="21" observatii="4 BUC x 24.18" valoarefaradiscount="96.72" tva="18.72" pretftva="19.50" valftva="78.00" nrlinie="35"/><row tert="1550829270616" contract="9810302" data="22/08/2012" cod="4300902008021" denumire="HK-Teu egal 20x20x20" cantitate="2" um="BUC" pretcatalog="0.53" cotatva="24" discount="0" yso_stocinstalatori="1" yso_pretcomlivr="0.53320" yso_disccomlivr="0.00" yso_gestpredte="211      " explicatii="NECHITA IOAN-9810302-22/08/2012" comanda_asis="1550829270616" pret="0.53" valoare="1.06" stocMaxim="2.000" gestiune="700" tipLinie="Produs" o_pretcatalog="0.53" tip="21" observatii="2 BUC x 0.53" valoarefaradiscount="1.06" tva="0.21" pretftva="0.43" valftva="0.85" nrlinie="36"/><row tert="1550829270616" contract="9810302" data="22/08/2012" cod="EVP-VT12FM" denumire=" TRUST-Supapa termostatica MF 1/2&quot;" cantitate="2" um="BUC" pretcatalog="1" cotatva="24" discount="0" yso_stocinstalatori="1" yso_pretcomlivr="31.22300" yso_disccomlivr="0.00" yso_gestpredte="211      " explicatii="NECHITA IOAN-9810302-22/08/2012" comanda_asis="1550829270616" pret="1" valoare="2" stocMaxim="2.000" gestiune="700" tipLinie="Produs" o_pretcatalog="1.00" tip="21" observatii="2 BUC x 1" valoarefaradiscount="2" tva="0.39" pretftva="0.81" valftva="1.61" nrlinie="37"/><row denumire="Numerar" tipLinie="Incasare" tip="31" pret="2057.08" cantitate="1" valoare="2057.08" nrlinie="38"/></pozitii></document></date>')
--exec wScriuDatePV @sesiune='750C51CE47F27',@parXML=@p2
--go
declare @p2 xml
set @p2=convert(xml,N'<row idAntetBon="1111" UID="0AECBE48-BDF4-904C-5A66-59161C4D1DC4"/>')
exec wDescarcBon @sesiune='750C51CE47F27',@parXML=@p2