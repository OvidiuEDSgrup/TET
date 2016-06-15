
create procedure corectiiInchidere @sesiune varchar(50), @parXML xml
as 
/*
Exemplu de apel:
	exec corectiiInchidere '','<parametri data="2013-07-31"/>'
*/
SET NOCOUNT ON
declare 
	@cSub varchar(20),@CtTvaNeexPlati varchar(20),@CtTvaNeexIncasari varchar(20),@CtTvaCol varchar(20),@CtTvaDed varchar(20)

select @cSub=val_alfanumerica from par where Tip_parametru='GE' and Parametru='SUBPRO'
select @CtTvaNeexPlati=Val_alfanumerica from par where Tip_parametru='GE' and Parametru='CNTLIFURN'
select @CtTvaNeexIncasari=Val_alfanumerica from par where Tip_parametru='GE' and Parametru='CNTLIBEN'
select @CtTvaCol=Val_alfanumerica from par where Tip_parametru='GE' and Parametru='CCTVA'
select @CtTvaDed=Val_alfanumerica from par where Tip_parametru='GE' and Parametru='CDTVA'

declare 
	@data datetime, @datajos datetime, @datasus datetime

select 
	@data=isnull(@parXML.value('(/parametri/@data)[1]','datetime'), '2999-01-01')

/**
	Pe baza parametrului DATA se contruiesc datajos si datasus cu BOM si EOM pentru filtrare mai departe(exemplu in PozDoc la cautare RP)
**/
select @datajos=dbo.BOM(@data), @datasus=dbo.EOM(@data)

-- 1. Colectam RP/RZ-urile --- regula: RP/RZ este legat de RM/RS prin numar si data

-- a. care nu au nici o legatura cu nici un RM sau RS din baza de date 

select 
	rp.idPozDoc
into #rpDeSters
from 
(
	select 
		pd.*
	from PozDoc pd where pd.Subunitate=@cSub and pd.Tip in ('RP','RZ') and data BETWEEN @datajos and @datasus
) rp
LEFT JOIN PozDoc RMRS ON 
	rp.Subunitate=@cSub and rp.Numar=RMRS.Numar and rp.Data=RMRS.Data and RMRS.Subunitate=@cSub and RMRS.Tip in ('RM','RS')
where rmrs.idPozDoc is null

/** Daca exista astfel de RP-uri le stergem */
if EXISTS (select 1 from #rpDeSters)
	delete p from PozDoc p JOIN #rpDeSters rds on p.idPozDoc=rds.idPozDoc

drop table #rpDeSters

-- b. Tratarea preturilor afectate de prestari pe receptii, daca nu mai exista RP-uri 
-- am comentat mai jos pana la stabilirea solutiei optime
/*IF EXISTS (select 1 from pozdoc where Subunitate=@csub and Tip in ('RP','RZ') and data between @datajos and @datasus) 
	OR
	EXISTS (select 1 from pozdoc where Subunitate=@csub and Tip in ('RM','RS')  AND Pret_de_stoc<>Pret_valuta and data between @datajos and @datasus and jurnal<>'MFX')

BEGIN
	declare 
		@crsdoc cursor, @tipd varchar(2), @numard varchar(20), @datad datetime, @ft bit

	/** Se iau documentele din cele doua situatii posibile de mai jos si pt fiecare (o singura data) se apeleaza repartizarea **/
	set @crsdoc= cursor local fast_forward for
		select distinct tip, numar, data 
		from 
		(	
			-- RP/RZ aferente unei RM/RS care nu au afectat pretul de stoc si nu vor fi selectate in cazul de dupa UNION  
			select rmrs.tip, rp.numar, rp.data
			from PozDoc rp 
			LEFT JOIN PozDoc rmrs ON rp.Subunitate=@cSub and rp.Numar=RMRS.Numar and rp.Data=RMRS.Data and RMRS.Subunitate=@cSub and RMRS.Tip in ('RM','RS')
			where rp.Subunitate=@csub and rp.Tip in ('RP','RZ') and rp.data between @datajos and @datasus 
				AND abs(rmrs.Pret_de_stoc-rmrs.Pret_valuta)<0.05 -- preturile egale
				and rmrs.stare<>2 -- stil vechi de doc. definitiv 
			UNION ALL
			-- RM/RS care au afectat pretul de stoc, probabil din cauza uui RP/RZ (nu e sigur, au fost excluse niste cazuri)  
			select 
				tip,numar, data
			from PozDoc where Subunitate=@csub and Tip in ('RM','RS') and data between @datajos and @datasus 
				AND abs(Pret_de_stoc-Pret_valuta)>0.001 -- preturi diferite 
				and not (valuta<>'' and abs(Pret_de_stoc-Pret_valuta*curs)<0.05 ) -- receptii in valuta fara prestari
				and not (discount<>0 and abs(Pret_de_stoc-Pret_valuta*(1+discount/100))<0.05 ) -- receptii cu cota fara prestari 
				and jurnal<>'MFX' 
				and stare<>2 -- stil vechi de doc. definitiv 
		)docprobleme

	open @crsdoc
	fetch next from @crsdoc into @tipd, @numard, @datad
	set @ft=@@fetch_status

	/** Parcurgem documentele */
	while @ft=0
	begin
		exec repartizarePrestariReceptii @tip=@tipd, @numar=@numard, @data=@datad
		fetch next from @crsdoc into @tipd, @numard, @datad
		set @ft=@@fetch_status
	end
END*/
	
/**
	Poate exista procedura SP care sa mai trateze si alte cazuri
**/
--if exists (select 1 from sysobjects where [type]='P' and [name]='corectiiInchidereSP1')
--	exec corectiiInchidereSP1 @sesiune=@sesiune, @parXML=@parXML

--exec contTVADocument @datalunii=@data

/**
	Poate exista procedura SP care sa mai trateze si alte cazuri
**/
if exists (select 1 from sysobjects where [type]='P' and [name]='corectiiInchidereSP')
	exec corectiiInchidereSP @sesiune=@sesiune, @parXML=@parXML
