create procedure wIaPozPrestariServicii @sesiune varchar(50),@parXML xml
as
declare @tipdocument char(2),@numar varchar(20),@data datetime,@subunitate char(9),@utilizator varchar(20),@lista_lm int,
	@tert varchar(13), @tip varchar(2)
	
select 	
	@tipdocument=@parXML.value('(/row/@tipdocument)[1]','char(2)'),
	@numar=@parXML.value('(/row/@numar)[1]','varchar(20)'),
	@data=@parXML.value('(/row/@data)[1]','datetime'),
	@tert=@parXML.value('(/row/@tert)[1]','varchar(13)'),
	@tip=@parXML.value('(/row/@tip)[1]','varchar(2)')

exec luare_date_par 'GE','SUBPRO',NULL,NULL,@subunitate OUT

EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT

if object_id('tempdb..#pozPrestari') is not null drop table #pozPrestari

select rtrim(p.tert) as tert,isnull(rtrim(t.denumire), '') as dentert,rtrim(p.factura) as factura, RTRIM(p.Cont_factura) as contfactura,
	convert(char(10),p.Data_facturii,101)as data_factura,convert(char(10),p.Data_scadentei,101) as data_scadentei, 
	isnull(rtrim(p.valuta),'') as valuta, convert(decimal(8,4),p.curs) as curs, 
	convert(decimal(14, 5), p.pret_valuta) as pret_valuta, -- valoarea in lei calculata din valoarea in valuta sau operata direct
	convert(decimal(5, 2), p.cota_tva) as cotatva, 
	convert(decimal(14,5),p.Pret_de_stoc) as ValoareFaraTVAvaluta_prest, -- valoarea in valuta
	case when isnull(p.valuta,'')<>'' and isnull(p.Curs,0)>0 then convert(decimal(14,5),p.pret_valuta/p.curs) else 0 end as pret_in_valuta,
	convert(varchar,p.Procent_vama) as tiptva, p.numar_pozitie as numarpozitie,convert(decimal(17,2),p.TVA_deductibil) as valTVA,
	(case when p.tip in ('RM','RC','RS','RP') and p.Procent_vama=0 then '0-TVA Deductibil'
		when p.tip in ('RM','RC','RS','RP') and p.Procent_vama=1 then '1-TVA Compensat'
		when p.tip in ('RM','RC','RS','RP') and p.Procent_vama=2 then '2-TVA Nedeductibil'
		else '' end ) as dentiptva,RTRIM(p.cod) as cod,'da' as _expandat, RTRIM(p.cod)+'-'+RTRIM(n.Denumire) as dencod,
	p.tip as tipprestare, case when p.tip='RP' then 'Prest.serv.ext.' else 'Prest.serv.int.' end as dentipprestare,
	case when p.tip='RZ' then '#033DED' else null end as culoare,
	p.tip as subtip,p.detalii,convert(int,p.accize_datorate) as accize_datorate,idPozdoc,
	/*	Linia de mai jos am pastrat-o pentru cazul in care nu s-a rulat AS\+webConfig si nu s-a actualizat configurarea tipului de repartizare in detalii. */
	(case when p.accize_datorate=1 then 'GREUTATE' else 'VALORIC' end) as tipRepartizarePrestari,
	convert(decimal(12,0),p.cantitate) as cantitate	
into #pozPrestari
from pozdoc p  
		left outer join nomencl n on n.cod = p.cod    
		left outer join terti t on t.subunitate = p.subunitate and t.tert = p.tert  
		left outer join lm on lm.cod = p.loc_de_munca  
		left outer join comenzi com on com.subunitate = p.subunitate and com.comanda = left(p.comanda,20)  
		left outer join indbug indb on indb.Indbug = substring(p.comanda,21,20)
		left outer join conturi ccor on p.tip not in ('RM', 'RS') and ccor.Subunitate=p.Subunitate and ccor.Cont=p.Cont_corespondent  
where p.subunitate=@subunitate 
		and (p.tip in ('RP','RZ'))
		and p.numar=@numar 
		and p.data=@data	
	order by p.numar_pozitie desc 
	
update d set 
	detalii='<row />'
from #pozPrestari d
where d.detalii is null

update d 
	set detalii.modify('insert attribute rep_greutate {sql:column("d.accize_datorate")} into (/row)[1]') 
from #pozPrestari d
where d.detalii.value('(/row/@rep_greutate)[1]','char(1)') is null 

select * from #pozPrestari
	order by numarpozitie desc  
for xml raw

select 1 areDetaliiXml for xml raw, root('Mesaje')
