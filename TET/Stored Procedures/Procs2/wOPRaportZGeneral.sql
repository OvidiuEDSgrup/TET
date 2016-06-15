--***
create procedure wOPRaportZGeneral @sesiune varchar(50), @parXML xml          
as        
-- exec wOPRaportZGeneral '', '<row dataj="2012-06-05" datas="2012-06-05"/>'
declare @dataj datetime, @datas datetime,@userASiS varchar(20),@sub varchar(20)

begin try  

	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS OUTPUT

	exec wJurnalizareOperatie @sesiune,@parXML,'wOPRaportZGeneral'

	IF EXISTS (select 1 from sysobjects where name ='wOPRaportZGeneralSP')
	begin
		exec wOPRaportZGeneralSP @sesiune=@sesiune, @parXML=@parXML
		return
	end

	select @dataj = ISNULL(@parXML.value('(/*/@dataj)[1]', 'datetime'), ''),       
	@datas = ISNULL(@parXML.value('(/*/@datas)[1]', 'datetime'), '')

	exec luare_date_par 'GE','SUBPRO',0,0,@sub output

	select bp.idantetbon,(case when n.tip='S' and n.cont like '7%' then n.cont else '707' end) as cont,sum(total) as total,bp.Cota_TVA
	into #vanzari
	from bp
	inner join nomencl n on bp.cod_produs=n.cod 
	where bp.idantetbon is not null
	and bp.tip='21'
	and bp.data between @dataj and @datas
	group by idantetbon,(case when n.tip='S' and n.cont like '7%' then n.cont else '707' end),bp.Cota_TVA

	alter table #vanzari add totalg float
	update #vanzari set totalg=v1.totalg
	from
	(select v2.idantetbon,sum(v2.total) as totalg
	from #vanzari v2
	group by v2.IdAntetBon) v1 where #vanzari.idantetBon=v1.idantetbon

	select bp.idantetbon,(case when bp.tip='31' then '5311.'+a.Gestiune
								when bp.tip='35' then '5128'
								 when bp.tip='36' then '5125'
								 end) as cont_casa,
	sum(total) as valinc
	into #incasari
	from bp
	inner join antetBonuri a on a.IdAntetBon=bp.IdAntetBon
	where bp.IdAntetBon is not null
	and bp.tip like '3%' 
	and bp.data between @dataj and @datas
	group by bp.idantetbon,
	(case when bp.tip='31' then '5311.'+a.Gestiune
								when bp.tip='35' then '5128'
								 when bp.tip='36' then '5125'
								 end)

	create table #cross (idantetbon int,Cota_tva decimal(12,2),cont varchar(20),cont_casa varchar(20),suma float)

	insert into #cross
	select v.idantetbon,v.Cota_tva,v.cont,i.cont_casa,v.total/v.totalg*i.valinc as suma
	from #vanzari v
	inner join #incasari i on v.IdAntetBon=i.idantetbon

	select ab.data_bon as data,cr.Cota_tva,ab.gestiune,ab.loc_de_munca,cr.cont_casa,cr.cont,sum(cr.suma) as total
	into #descris
	from #cross cr
	inner join antetbonuri ab on cr.idantetbon=ab.idantetbon
	group by ab.data_bon,ab.gestiune,ab.loc_de_munca,cr.cont_casa,cr.cont,cr.Cota_tva
	order by ab.data_bon,ab.gestiune,ab.loc_de_munca,cr.cont_casa,cr.cont,cr.Cota_tva

	--Fiind vorba de o operatie cu multe linii vom insera direct date in PozPlin

		  delete from pozplin where 
		  subunitate=@sub and plata_incasare='IC' and data between @dataj and @datas
		  and explicatii='Vanzari PVRIA'

		  INSERT INTO pozplin(Subunitate, Cont, Data, Numar, Plata_incasare, Tert, Factura, Cont_corespondent, Suma, 
		  Valuta, Curs, Suma_valuta, Curs_la_valuta_facturii, TVA11, TVA22, Explicatii, Loc_de_munca, Comanda, Utilizator, 
		  Data_operarii, Ora_operarii, Numar_pozitie, Cont_dif, Suma_dif, Achit_fact, Jurnal)
		  select @sub, sc.cont_casa,sc.data,
		  rtrim(sc.gestiune)+right(replace(convert(char(10),getdate(),102),'.',''),4) as numar,
		  'IC','',rtrim(sc.gestiune)+right(replace(convert(char(10),getdate(),102),'.',''),4) as factura,
		  sc.cont as cont_corespondent,sc.total,'', 0, 0, 0, sc.Cota_tva,round(sc.total*(1.00-1.00/(1.00+sc.Cota_tva/100)),2),'Vanzari PVRIA',isnull(sc.loc_de_munca,gc.loc_de_munca),
		  '',@userASiS,convert(datetime,convert(char(10),GETDATE(),110),110),
		  replace((convert(char(9), substring(convert(char(30),GETDATE(),108),1,9))),':',''), row_number() over (order by sc.data,sc.loc_de_munca,sc.cont_casa,sc.cont) as nrpoz, 
		  '', 0, 0, ''
		  from #descris sc
		  left outer join gestcor gc on sc.gestiune=gc.gestiune
		  order by sc.data,sc.loc_de_munca,sc.cont_casa,sc.cont
end try  

begin catch  
	declare @eroare varchar(2000)
	set @eroare=ERROR_MESSAGE()+'(wOPRaportZGeneral)'
	raiserror(@eroare, 16, 1) 
end catch
