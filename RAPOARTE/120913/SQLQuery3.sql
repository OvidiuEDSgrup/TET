--select * from docfiscale d order by d.TipDoc

--select * from Tally t cross apply (select top 1 * from docfiscale where ID=6) d 
--where t.N between 1 and d.NumarSup+200000-d.NumarInf
--where not 

select t.*,convert(varchar,t.N) from Tally t 
inner join (select top 1 * from docfiscale where ID=1) d on t.n between d.NumarInf and d.UltimulNr
left join 
		(select factura
			=isnull(case when p.Tip IN ('AP','AS') then case tl.N when 1 then pa.Factura_stinga else p.Factura end
					when p.Tip='AC' then ab.Factura 
					else p.Factura end
			,p.factura) 
		--,Data_facturii=isnull(case p.Tip when 'AP' then pa.Data_fact when 'AC' then ab.Data_facturii else p.Data_facturii end, p.Data_facturii)
		from pozdoc p  
		  left outer join nomencl n on p.cod=n.cod  
		  left outer join anexaFac a on a.subunitate=p.subunitate and a.numar_factura=p.factura   
		  left outer join antetBonuri b on isnull(nullif(b.bon.value('(/date/document/@numar_in_pozdoc)[1]','varchar(50)'),'')
			,left(rtrim(convert(varchar(4),b.Casa_de_marcat))+right(replace(str(b.Numar_bon),' ','0'),4),8))=p.numar
			and b.Data_bon=p.Data and b.Chitanta=1 
		  left outer join antetBonuri ab on ab.Chitanta=0 and ab.Factura=b.Factura and ab.Data_facturii=b.Data_facturii
		  left outer join par on par.Tip_parametru='GE' and par.Parametru='CTCLAVRT' 
		  left outer join pozadoc pa on pa.Subunitate=p.Subunitate and pa.Tip='IF' and pa.Factura_dreapta=p.Factura
		  left outer join Tally tl on pa.Factura_stinga is not null and tl.N between 1 and 2
		where p.subunitate='1' and p.tip in ('AC','AP','AS')
			/*and (not(p.Tip in ('AP','AS') and p.Cont_factura =isnull(par.Val_alfanumerica,'418.0')) 
				or pa.Factura_stinga is not null)*/
			and (p.tip<>'AC' or ab.Factura is not null)
		  group by isnull(case when p.Tip IN ('AP','AS') then case tl.N when 1 then pa.Factura_stinga else p.Factura end
						when p.Tip='AC' then ab.Factura 
						else p.Factura end
				,p.factura)) f
	on f.Factura=convert(varchar,t.N)
where f.factura is null
