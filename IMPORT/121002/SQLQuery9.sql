select a.subunitate, a.gestiune, a.cont, a.cod, a.data, a.data_stoc, a.cod_intrare, a.pret, 
(case when 0=1 and 0=1 /*pare ca nu trebuie - cursorul din pozincon ia PI/FI pe parte de credit*/ then (case a.tip_document when 'FI' then 'DF' when 'PI' then 'PF' else a.tip_document end) else a.tip_document end) as tip_document, 
a.numar_document, (case when 0=0 then a.cantitate else a.cantitate_UM2 end) as cantitate, a.tip_miscare, a.in_out, a.predator, a.jurnal, a.tert, a.serie, 
a.pret_cu_amanuntul-(case when 0=1 and a.tip_document in ('TE', 'TI') and a.cont=a.cont_corespondent then a.pret else 0 end) as pret_cu_amanuntul,
a.tip_gestiune, a.locatie, a.data_expirarii, a.TVA_neexigibil, a.pret_vanzare, a.accize_cump,
a.comanda, a.furnizor, a.contract, a.loc_de_munca
--into tempdb..balst77121                                 
from dbo.fStocuri('08/01/2012', '08/31/2012', null, '211', null, '', 'D', '', 0, '', '', '', '', '', '                    ') a
where (''='' or a.gestiune like RTrim(''))
and (0=0 or a.tip_gestiune='A')
and (0=0 or left(a.locatie, 30 )='')
and (''='' or a.comanda='') 
and (''='' or a.furnizor='') 
and (''='' or a.contract='') 
and (''='' or a.loc_de_munca='') 
and ('                    '='' or a.lot='                    ')
and not (0=1 and a.tip_document in ('TE', 'TI') and a.cont=a.cont_corespondent and a.tip_gestiune not in ('A', 'V'))
and (0=0 or a.tip_gestiune in ('F', 'T') or exists (select 1 from gesttmpid gt where gt.gestiune=a.gestiune and gt.HostId='7712'))
and (0=0 or exists (select 1 from personal where personal.marca=a.gestiune and personal.loc_de_munca like RTrim('211')+'%'))
and (0=0 or abs(a.cantitate_UM2)>=0.001)


select (case when  1 =5 or  1 =6   then (select isnull(loc_de_munca,'') from personal where personal.marca=a.gestiune) when  1 =2 then n.grupa  else a.gestiune end) as gest, (case when  1 =10 then substring(a.locatie,15,16) when  1 =9 then /*left(a.locatie,13)*/a.comanda when  1 =6 or  1 =2   then a.gestiune when  1 =7 then n.grupa when  1 =12 or  1 =11 then a.locatie else a.cont end) as cont_marca, a.cod, a.data, 
(case when 0=1 then tip_document+numar_document when '0'=1 then convert(char(15)
,convert(decimal(10,3),a.Pret)) when 0=1 then a.serie else a.cod_intrare end), 
(case when 0=1 then 0 when 0=1 then ((case when 0=0 and not (0=1 and a.tip_gestiune='A') then b.pret 
else b.pret_cu_amanuntul end) 
/ isnull((select top 1 curs.curs from curs where curs.valuta='   ' and curs.data <= b.data order by curs.data DESC), 1)) 
	when 0=0 and not (0=1 and a.tip_gestiune='A') then a.pret else a.pret_cu_amanuntul end)
	, a.tip_document, a.numar_document, 
a.cantitate, a.tip_miscare, n.grupa, a.predator, isnull(b.data,a.data_stoc), 
(case when  1  in (1,2,6,7,12) then ''  when  1 =10 then substring(a.locatie,15,16) when  1 =9 then /*left(a.locatie,13)*/a.comanda when  1 =11 then  a.locatie else a.cont end) as cont_ordonare, a.jurnal, a.tert, a.locatie, (case when  1 =10 and left(a.locatie,13)<>'' then left(a.locatie,13) when 0=1 and  1 =9 and substring(a.locatie,15,16)<>'' then substring(a.locatie,15,16) else space(16) end) as com_ord,
isnull(n.tip, '') as tip_nom, isnull(n.denumire, '') as denumire_nom, isnull(n.UM, '') as UM_nom, isnull(n.grupa, '') as grupa_nom, isnull(n.loc_de_munca, '') as lm_nom, 
(case when 0=1 then convert(char(10),a.data,102) else (case when 0=1 then  tip_document+numar_document else 
(case when '0'=1 then convert(char(18),convert(decimal(12,3),a.Pret)) when 0=1 then a.serie else convert(char(10),isnull(b.data,'01/01/1901'),102)+a.cod_intrare end)+'1' end) 
+(case when (a.tip_document='SI' and 0=0) then '' else convert(char(10),a.data,102) end) end) as ord, 
(case when 0=1 then isnull(left((case when 0=1 then n.loc_de_munca else n.denumire end),45),'') else '' end) as den, a.in_out 
from tempdb..balst77121 a 
left outer join nomencl n on a.cod=n.cod 
left outer join stocuri b on a.subunitate=b.subunitate and a.tip_gestiune=b.tip_gestiune and a.gestiune=b.cod_gestiune and a.cod=b.cod and a.cod_intrare=b.cod_intrare 
where isnull(n.grupa,'') like rtrim('             ')+'%' and isnull(n.UM,'') like rtrim('   ')+'%' and (0=0 or isnull(right(n.tip_echipament,20),'')='                    ') and (0=0 or a.tip_gestiune in ('F', 'T') or a.gestiune in (select gestiune from gesttmpid where HostId='7712')) 
and (' '='' or ' '='M' and left(a.cont,3) not in ('345','354','371','357') or ' '='P' and left(a.cont,3) in ('345','354') or ' '='A' and left(a.cont,3) in ('371','357')) and (0=0 or isnull(n.loc_de_munca,'')='                                                                                                                                                      ') 
order by cont_ordonare, com_ord, gest, cont_marca, den, a.cod, ord , a.in_out