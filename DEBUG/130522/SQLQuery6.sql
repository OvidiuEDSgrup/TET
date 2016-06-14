select numar, data, furnizor, codfisc, total, baza_19, tva_19, baza_9, tva_9, scutite, baza_intra, tva_intra, scutite_intra, neimpoz_intra, baza_oblig_1, tva_oblig_1, baza_oblig_2, tva_oblig_2, 
(case when 0=1 then cont_tva else right(replace(convert(char(10), data, 104),'.',' '),6) end) as luna_anul_str,
detal_doc, care_jurnal, tip_doc, nr_doc, data_doc, valoare_doc, cota_tva_doc, suma_tva_doc,
(case when 0=1 then cont_tva else '' end) as ord_cont_tva

from dbo.jurnalTVACumparari ('04/01/2013', '04/30/2013', '', '', '', 0, '', '', 0, 0, 0, '0', '0', 0,          1.00000000 , 0, 0, 0, 0, '',     0.05 , '             ', '                    ', 0,' ',0,0, '                                                                                                                                                                                                        ', 2 , 0, '<row />') j
left outer join terti t on t.subunitate='1        ' and t.tert=j.cod_tert
left outer join infotert it on it.subunitate='1        ' and it.tert=j.cod_tert and it.identificator=''
where ('   '='' or isnull(t.grupa, '')='   ') and (0=0 or isnull(it.zile_inc, -1)=0)
	and (0=0 or isnull((select top 1 tt.tip_tva from tvapeterti tt where tt.tert=j.cod_tert and tt.tipf='F' and tt.dela<='04/30/2013' and isnull(tt.factura,'')='' order by tt.dela desc),'P')=(case when 0=1 then 'P' when 0=2 then 'N' else 'I' end) /*isnull(it.Grupa13,0)=0-1*/)
and furnizor like '%kamena%'
order by ord_cont_tva, (case when 0=1 then furnizor+numar+convert(char(10),data,102) else convert(char(10),data,102)+numar end), detal_doc, data_doc, tip_doc, nr_doc

select * from infotert i inner join terti t on t.Tert=i.Tert
where t.Denumire like '%kamena%'

exec dbo.yso_pjurnalTVACumparari '04/01/2013', '04/30/2013', '', '', '', 0, '', '', 0, 0, 0, '0', '0', 0,          1.00000000 
, 0, 0, 0, 0, '',     0.05 , 'RO15807344', '                    ', 0,' ',0,0, '                                                                                                                                                                                                        ', 2 , 0, '<row />'

exec yso_pdocTVACump
'2013-04-01','2013-04-30','','','',0,'','',0,0,0,0,0,0,1,0,0,0,'RO15807344   ','',0,0,2,'<row />'