--***
create procedure inregDocAvizeGestTipA @sesiune varchar(50), @parXML xml OUTPUT
as 
declare @cAdaos varchar(40), @anGestAdaos int, @cTvaNeexigil varchar(40), @anCtTvaNeexigibil int

select top 1 @cAdaos=rtrim(val_alfanumerica),@anGestAdaos=val_logica from par where Tip_parametru='GE' and Parametru='CADAOS'
select top 1 
	@cTvaNeexigil=rtrim(val_alfanumerica),
	@anCtTvaNeexigibil=val_logica 
from par where Tip_parametru='GE' and Parametru='CNTVA'
if @cTvaNeexigil is null
	set @cTvaNeexigil='4428'

begin try
--	incarcare / descarcare Adaos prin diferenta intre pretul de amanunt si pretul de amanunt predator
	insert into #pozincon(TipInregistrare,Subunitate, Tip, Numar, Data, Valuta, Curs, Suma_valuta, Utilizator, Loc_de_munca, Comanda, Jurnal,Cont_debitor, Cont_creditor, Suma,Explicatii, Data_operarii, Ora_operarii)
	select 'IADAOSAP',p.subunitate,p.tip,p.numar,p.data,'',0,0,max(p.utilizator),p.loc_de_munca,p.comanda,p.jurnal,
	p.cont_de_stoc,rtrim(@cAdaos)+(case when @anGestAdaos=1 then '.'+rtrim(p.Gestiune) else '' end),
	sum(round(convert(decimal(17,5),cantitate*Pret_cu_amanuntul),2)-round(convert(decimal(17,5),cantitate*pret_de_stoc),2)
		-round(convert(decimal(17,5),cantitate*p.TvaNeexUnitarIntrare),2))
	-sum(round(convert(decimal(17,5),p.cantitate*p.Pret_amanunt_predator),2)-round(convert(decimal(17,5),p.cantitate*pret_de_stoc),2)
		-round(convert(decimal(17,5),p.cantitate*p.TvaNeexUnitarIesire),2)) as valoare,
	isnull(max(p.explicatiidindetalii),max(g.denumire_gestiune)) as explicatii,
	max(p.data_operarii), max(p.ora_operarii)
	from #pozdoc p
	inner join gestiuni g on p.Subunitate=g.Subunitate and p.gestiune=g.cod_gestiune
	where p.tip in ('AP','AC') and p.tip_miscare='E' and g.tip_gestiune='A'
		and LEFT(p.Cont_de_stoc,3)='371'
	group by p.subunitate,p.tip,p.numar,p.data,p.loc_de_munca,p.comanda,p.valuta,p.curs,p.Gestiune,p.Cont_de_stoc,p.valuta,p.curs,p.jurnal

	insert into #pozincon(TipInregistrare,Subunitate, Tip, Numar, Data, Valuta, Curs, Suma_valuta, Utilizator, Loc_de_munca, Comanda, Jurnal,Cont_debitor, Cont_creditor, Suma,Explicatii, Data_operarii, Ora_operarii)
	select 'DADAOSAP',p.subunitate,p.tip,p.numar,p.data,'',0,0,max(p.utilizator),p.loc_de_munca,p.comanda,p.jurnal,
	@cAdaos+(case when @anGestAdaos=1 then '.'+p.Gestiune else '' end),p.cont_de_stoc,
	sum(round(convert(decimal(17,5),p.cantitate*p.Pret_cu_amanuntul),2)-round(convert(decimal(17,5),p.cantitate*pret_de_stoc),2)
		-round(convert(decimal(17,5),p.cantitate*p.TvaNeexUnitarIntrare),2))
	-sum(round(convert(decimal(17,5),p.cantitate*p.Pret_amanunt_predator),2)-round(convert(decimal(17,5),p.cantitate*pret_de_stoc),2)
		-round(convert(decimal(17,5),p.cantitate*p.TvaNeexUnitarIesire),2)) as valoare,
	isnull(max(p.explicatiidindetalii),max(g.denumire_gestiune)) as explicatii,
	max(p.data_operarii), max(p.ora_operarii)
	from #pozdoc p
	inner join gestiuni g on p.Subunitate=g.Subunitate and p.gestiune=g.cod_gestiune
	where p.tip in ('AP','AC') and p.tip_miscare='E' and g.tip_gestiune='A'
		and LEFT(p.Cont_de_stoc,3)='371'
	group by p.subunitate,p.tip,p.numar,p.data,p.loc_de_munca,p.comanda,p.valuta,p.curs,p.Gestiune,p.Cont_de_stoc,p.valuta,p.curs,p.jurnal

--	incarcare / descarcare TVA neexigibil 
	insert into #pozincon(TipInregistrare,Subunitate, Tip, Numar, Data, Valuta, Curs, Suma_valuta, Utilizator, Loc_de_munca, Comanda, Jurnal,Cont_debitor, Cont_creditor, Suma,Explicatii, Data_operarii, Ora_operarii)
	select 'ITVANEXAP',p.subunitate,p.tip,p.numar,p.data,'',0,0,max(p.utilizator),p.loc_de_munca,p.comanda,p.jurnal,
	p.cont_de_stoc,rtrim(@cTvaNeexigil)+(case when @anCtTvaNeexigibil=1 then '.'+rtrim(p.Gestiune) else '' end),
	sum(round(convert(decimal(17,5),p.Cantitate*(p.TvaNeexUnitarIntrare-p.TvaNeexUnitarIesire)),2)) as valoare,
	isnull(max(p.explicatiidindetalii),max(g.denumire_gestiune)) as explicatii,
	max(p.data_operarii), max(p.ora_operarii)
	from #pozdoc p
	inner join gestiuni g on p.Subunitate=g.Subunitate and p.gestiune=g.cod_gestiune
	where p.tip in ('AP','AC') and p.tip_miscare='E' and g.tip_gestiune='A'
		and LEFT(p.Cont_de_stoc,3)='371'
	group by p.subunitate,p.tip,p.numar,p.data,p.loc_de_munca,p.comanda,p.valuta,p.curs,p.Gestiune,p.Cont_de_stoc,p.valuta,p.curs,p.jurnal

	insert into #pozincon(TipInregistrare,Subunitate, Tip, Numar, Data, Valuta, Curs, Suma_valuta, Utilizator, Loc_de_munca, Comanda, Jurnal,Cont_debitor, Cont_creditor, Suma,Explicatii, Data_operarii, Ora_operarii)
	select 'DTVANEXAP',p.subunitate,p.tip,p.numar,p.data,'',0,0,max(p.utilizator),p.loc_de_munca,p.comanda,p.jurnal,
	@cTvaNeexigil+(case when @anCtTvaNeexigibil=1 then '.'+p.Gestiune else '' end),p.cont_de_stoc,
	sum(round(convert(decimal(17,5),p.Cantitate*(p.TvaNeexUnitarIntrare-p.TvaNeexUnitarIesire)),2)) as valoare,
	isnull(max(p.explicatiidindetalii),max(g.denumire_gestiune)) as explicatii,
	max(p.data_operarii), max(p.ora_operarii)
	from #pozdoc p
	inner join gestiuni g on p.Subunitate=g.Subunitate and p.gestiune=g.cod_gestiune
	where p.tip in ('AP','AC') and p.tip_miscare='E' and g.tip_gestiune='A'
		and LEFT(p.Cont_de_stoc,3)='371'
	group by p.subunitate,p.tip,p.numar,p.data,p.loc_de_munca,p.comanda,p.valuta,p.curs,p.Gestiune,p.Cont_de_stoc,p.valuta,p.curs,p.jurnal
end try

begin catch
	declare @mesaj varchar(8000)
	set @mesaj =ERROR_MESSAGE()+' (inregDocAvizeGestTipA)'
	raiserror(@mesaj, 11, 1)
end catch
