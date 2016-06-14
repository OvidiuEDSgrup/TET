select col=dbo.fStrToken(substring(f.expresie,charindex(ltrim(rtrim(p.alias)),convert(varchar(max),f.expresie)),len(convert(varchar(max),f.expresie))),2,'.')
,* from formular f join antform a on a.Numar_formular=f.formular
cross apply (select alias=dbo.fStrToken(replace(substring(a.CLFrom,CHARINDEX('pozconexp',a.CLFrom),LEN(a.CLFrom)),' ',';'),2,';') 
,idx=CHARINDEX('pozconexp',a.CLFrom)
,leng=LEN(a.CLFrom)
,subs=substring(a.CLFrom,CHARINDEX('pozconexp',a.CLFrom),LEN(a.CLFrom))
,pct=replace(substring(a.CLFrom,CHARINDEX('pozconexp',a.CLFrom),LEN(a.CLFrom)),' ',';')
,a.CLFrom
,tok=dbo.fStrToken('pozconexp pozcon ON',2,' ')
) p
where a.CLFrom like '%pozconexp%' and f.expresie like '%'+ltrim(rtrim(p.alias))+'.'+'%'
--FROM avnefac JOIN con ON avnefac.subunitate=con.subunitate and avnefac.tip=con.tip and avnefac.contractul=con.contract and avnefac.cod_tert=con.tert and avnefac.data=con.data JOIN yso.pozconexp pozcon ON pozcon.subunitate=con.subunitate and pozcon.tip=con.tip and pozcon.contract=con.contract and pozcon.data=con.data and pozcon.tert=con.tert LEFT JOIN terti ON terti.subunitate=con.subunitate and terti.tert=con.tert LEFT JOIN nomencl ON nomencl.cod=pozcon.cod and nomencl.cod=pozcon.cod                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
--pozconexp pozcon ON pozcon.subunitate=con.subunitate and pozcon.tip=con.tip and pozcon.contract=con.contract and pozcon.data=con.data and pozcon.tert=con.tert LEFT JOIN terti ON terti.subunitate=con.subunitate and terti.tert=con.tert LEFT JOIN nomencl ON nomencl.cod=pozcon.cod and nomencl.cod=pozcon.cod                                                                                                                                                                                        