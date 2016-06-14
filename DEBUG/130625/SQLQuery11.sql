select * from
(select subunitate,tert,sold,sursa='F' from facturi where facturi.Tip=0x46 and abs(facturi.Sold)>=0.001
					union all select subunitate,tert,sold,sursa='E' from efecte where efecte.Tip='I' and abs(efecte.Sold)>=0.001
					union all select s.subunitate,ISNULL(pc.tert,s.Comanda),s.Stoc*convert(decimal(15,2),s.Pret_cu_amanuntul),sursa='S'
						from stocuri s 
							inner join nomencl n on s.cod=n.cod
							left join pozcon pc on pc.Subunitate=s.Subunitate and pc.Tip='BK' and pc.Contract=s.Contract 
								and pc.Cod=s.Cod
							inner join terti on terti.Subunitate=s.Subunitate and terti.tert=ISNULL(pc.tert,s.Comanda)
						where s.Cod_gestiune='700' and s.stoc>=0.001) s
						where s.tert='RO18836620'
						
						select * from facturi f where f.tert='RO18836620' and f.Sold>0
						
/*
<row Tert="RO18836620   " sursa="F" soldv="7040.10" soldi="3520.05" soldm="15000.00"/>
<row Tert="RO18836620   " sursa="E" soldv="2872.36" soldi="3520.05" soldm="15000.00"/>
<row Tert="RO18836620   " sursa="E" soldv="5632.08" soldi="3520.05" soldm="15000.00	xml
*/