
CREATE PROCEDURE AdaugIdIntrareFirma @sesiune VARCHAR(50)='', @parXML XML=''
AS
begin try
	declare @wscriudoc bit, @wscriudocbeta bit
	select @wscriudoc=0, @wscriudocbeta=0
	if exists(select 1 from sysobjects where name='wScriuDoc')
		select @wscriudoc=1
	if @wscriudoc=0 and exists(select 1 from sysobjects where name='wScriuDocBeta')
		select @wscriudocbeta=1
	if @wscriudoc=0	and @wscriudocbeta=0
		return

	declare	@versiuneAdaugIntrareFirma int,@versiuneCurentaAdaugIntrareFirma int
	select @versiuneCurentaAdaugIntrareFirma=1,@versiuneAdaugIntrareFirma=0
	select top 1 @versiuneAdaugIntrareFirma=val_numerica from par where Tip_parametru='GE' and parametru='ADAUGIDIF'

	if (@versiuneAdaugIntrareFirma<@versiuneCurentaAdaugIntrareFirma or not exists (select 1 from stocuri where idintrarefirma is not null))
	/*Pentru a face o singura data pe o firma, eventual se mai poate apela la un fel de refacere daca s-au varzalit legaturile*/
	begin
		/*Punem stocul initial pentru a putea avea idIntrareFirma si in cazul stocului initial*/
		declare 
			@nAnImpl int,@nLunaImpl int,@dDImpl datetime,@lm varchar(20),@pX xml,@cSub varchar(20),@tert varchar(20),@nrInit varchar(20)
		select @nAnImpl=isnull((select max(val_numerica) from par where tip_parametru='GE' and parametru='ANULIMPL'),1901)
		select @nLunaImpl=isnull((select max(val_numerica) from par where tip_parametru='GE' and parametru='LUNAIMPL'),0)
		select @cSub=isnull((select max(Val_alfanumerica) from par where tip_parametru='GE' and parametru='SUBPRO'),'1')
		select
			@dDImpl=dateadd(day,-1,dateadd(month,@nLunaImpl,dateadd(year,@nAnImpl-1901,'01/01/1901'))),
			@nrInit='STOCINIT'

		select top 1 @lm=rtrim(cod) from lm order by cod
		select top 1 @tert=tert from terti
		if object_id('tempdb..#tipstoc') is not null drop table #tipstoc
		select 'D' as tipstoc	--Depozit
		into #tipstoc
		union all				--Folosinta
		select 'F' as tipstoc

		select @pX=
		(
			select 
				(case when ts.tipstoc='F' then 'FI' else 'SI' end) as tip,@lm as lm,@nrInit as numar,@tert as tert,
				(
					select 
						Tip_gestiune, convert(char(10),(case when data>@dDImpl then @dDImpl else data end),101) as data,rtrim(Cod_gestiune) as gestiune,rtrim(cod) as cod,convert(decimal(12,4),stoc) as cantitate,
						rtrim(cont) as contstoc,cod_intrare as codintrare,
						convert(decimal(12,5),pret) as pstoc,convert(char(10),data_expirarii,101) as dataexpirarii,rtrim(lot) as lot,rtrim(furnizor) as tert
					from istoricstocuri where Data_lunii=@dDImpl and (ts.tipstoc='F' and Tip_Gestiune='F' or ts.tipstoc='D' and Tip_Gestiune<>'F')
					for xml raw,type
				)
			from #tipstoc ts
			for xml raw, root('Date')--type
		)
	
		alter table pozdoc disable trigger all
		begin transaction initial
			delete from pozdoc where subunitate=@cSub and tip in ('SI','FI') and numar=@nrInit --and data=@dDImpl
			if @wscriudoc=1
				exec wScriuDoc @sesiune,@pX
			if @wscriudocbeta=1
				exec wScriuDocBeta @sesiune,@pX
		commit transaction initial
		alter table pozdoc enable trigger all

return
		/*Gata cu stocul initial*/
		create table #pd(tip char(2),subunitate varchar(20),gestiune varchar(20),cod varchar(20),cod_intrare varchar(20),data datetime,cantitate float,idPozDoc int,tip_miscare char(1),pas int,idIntrareFirma int)
		insert into #pd(tip,subunitate,gestiune,cod,Cod_intrare,data,cantitate,idPozDoc,Tip_miscare)
		select tip,p.subunitate,p.gestiune,p.cod,p.Cod_intrare,data,p.cantitate,p.idPozDoc,p.Tip_miscare
		from pozdoc p
		--inner join gestiuni g on p.gestiune=g.Cod_gestiune
		left outer join gestiuni g on p.tip not in ('PF','CI','AF') and g.subunitate=p.subunitate and g.cod_gestiune=p.gestiune
		where isnull(g.Tip_gestiune,'')!='V' and p.Tip_miscare in ('I','E') --and p.cod='872790025242260' --Pentru DEBUG
		union all
		select 'TI',p.subunitate,p.gestiune_primitoare,p.cod,p.grupa,p.data,p.cantitate,p.idPozDoc,'I'
		from pozdoc p
		inner join gestiuni g on p.Gestiune_primitoare=g.Cod_gestiune
		where p.tip='TE' and g.Tip_gestiune!='V' and p.Tip_miscare in ('I','E') --and p.cod='872790025242260' --Pentru DEBUG
		/*Aici citit documentele similare TE-urilor pentru folosinta. Le-am pus separat si nu in acelasi script cu TE-urile ca sa se vada mai usor. */
		union all
		select 'PI',p.subunitate,p.gestiune_primitoare,p.cod,(case when p.grupa='' then p.cod_intrare else p.Grupa end),p.data,p.cantitate,p.idPozDoc,'I'
		from pozdoc p
		inner join personal s on p.Gestiune_primitoare=s.marca
		where p.tip='PF' and p.Tip_miscare in ('I','E') --and p.cod='03100004' --Pentru DEBUG
		union all
		select 'DI',p.subunitate,p.gestiune_primitoare,p.cod,(case when p.grupa='' then p.cod_intrare else p.Grupa end),p.data,p.cantitate,p.idPozDoc,'I'
		from pozdoc p
		inner join personal s on p.Gestiune_primitoare=s.marca
		where p.tip='DF' and p.Tip_miscare in ('I','E') --and p.cod='03100004' --Pentru DEBUG

		create table #stocuri(subunitate varchar(20),gestiune varchar(20),cod varchar(20),cod_intrare varchar(20),idIntrare int)

		insert into #stocuri
		select subunitate,gestiune,cod,cod_intrare,null as idIntrare
		from #pd
		group by subunitate,gestiune,cod,cod_intrare

		declare @masterPAS int,@pas int,@nrRanduriDeRezolvat int,@nrRanduriDeRezolvatAnterior int
		select @nrRanduriDeRezolvat=1

		select @masterPAS=0,@pas=0
		while @masterPAS<6 and @nrRanduriDeRezolvat>0
		begin
			/** Punem mai multe randuri unul standard si unul de rezolvare erori (punem alte intrari dupa ureche dupa care incercam sa rezolvam din nou iesiri
				Daca masterPAS-ul este zero inseamna ca ne bazam pe receptii
				La masterPAS=1 cautam stocuri din AlteIntrari carora le vom da un idIntrareFirma ca si cel al miscarii anterioare pe aceeasi gestiune si cod**/
		
			if @masterPAS=0 --La receptii si la predari e clar idIntrareFirma=idPozDoc
			begin
				update #pd set idIntrareFirma=idPozdoc,pas=0
				where tip in ('SI','FI','RM','PP')
			end
		
			if @masterPAS=1 --La AI/uri sau iesiri cu minus se ia ca si idIntrareFirma precedenta completata. Am asimilat AF-urile la AI-uri.
			begin
				update #pd set idIntrareFirma=pIntrare.idIntrareFirma,pas=@pas
				from #pd
					cross apply (select top 1 pd1.idPozDoc from #pd pd1 where pd1.idIntrareFirma is not null and 
					pd1.cod=#pd.cod and pd1.gestiune=#pd.gestiune 
						and pd1.data<=#pd.data and pd1.tip_miscare='I' order by pd1.data desc) pd2 
					inner join #pd pintrare on pd2.idPozDoc=pintrare.idPozDoc
					where #pd.idIntrareFirma is null and (#pd.tip in ('AI','AF') or #pd.tip_miscare='E' and #pd.cantitate<0)
			end

			if @masterPAS=2 --Se ia orice idIntrareFirma anterior intrarii cel mai apropiat de momentul intrarii pe GESTIUNE
			begin
				update #pd set idIntrareFirma=pIntrare.idIntrareFirma,pas=@pas
				from #pd
					cross apply (select top 1 pd1.idPozDoc from #pd pd1 where pd1.idIntrareFirma is not null and 
					pd1.cod=#pd.cod and pd1.gestiune=#pd.gestiune 
						and pd1.data>=#pd.data and pd1.tip_miscare='I' order by pd1.data) pd2 
					inner join #pd pintrare on pd2.idPozDoc=pintrare.idPozDoc
					where #pd.idIntrareFirma is null and (#pd.tip in ('AI','AF') or #pd.tip_miscare='E' and #pd.cantitate<0)
			end
			update #stocuri set idIntrare=idIntrareFirma
			from #pd p
			inner join #stocuri s on s.Subunitate=p.Subunitate and s.Gestiune=p.Gestiune and s.Cod=p.Cod and s.Cod_intrare=p.Cod_intrare
			where p.pas=@pas and p.idIntrareFirma is not null


			if @masterPAS=3 --Se ia orice idIntrareFirma si ulterior intrarii cel mai apropiat de momentul intrarii pe GESTIUNE
			begin
				update #pd set idIntrareFirma=pIntrare.idIntrareFirma,pas=@pas
				from #pd
					cross apply (select top 1 pd1.idPozDoc from #pd pd1 where pd1.idIntrareFirma is not null and 
					pd1.cod=#pd.cod and pd1.gestiune=#pd.gestiune 
						and pd1.data>=#pd.data and pd1.tip_miscare='I' order by pd1.data) pd2 
					inner join #pd pintrare on pd2.idPozDoc=pintrare.idPozDoc
					where #pd.idIntrareFirma is null and (#pd.tip in ('AI','AF') or #pd.tip_miscare='E' and #pd.cantitate<0)
			end
			update #stocuri set idIntrare=idIntrareFirma
			from #pd p
			inner join #stocuri s on s.Subunitate=p.Subunitate and s.Gestiune=p.Gestiune and s.Cod=p.Cod and s.Cod_intrare=p.Cod_intrare
			where p.pas=@pas and p.idIntrareFirma is not null
		
			if @masterPAS=4 --Se ia orice idIntrareFirma anterior intrarii cel mai apropiat de momentul intrarii pe FIRMA
			begin
				update #pd set idIntrareFirma=pIntrare.idIntrareFirma,pas=@pas
				from #pd
					cross apply (select top 1 pd1.idPozDoc from #pd pd1 where pd1.idIntrareFirma is not null and 
					pd1.cod=#pd.cod 
						and pd1.data>=#pd.data and pd1.tip_miscare='I' order by pd1.data) pd2 
					inner join #pd pintrare on pd2.idPozDoc=pintrare.idPozDoc
					where #pd.idIntrareFirma is null and (#pd.tip in ('AI','AF') or #pd.tip_miscare='E' and #pd.cantitate<0)
			end
			update #stocuri set idIntrare=idIntrareFirma
			from #pd p
			inner join #stocuri s on s.Subunitate=p.Subunitate and s.Gestiune=p.Gestiune and s.Cod=p.Cod and s.Cod_intrare=p.Cod_intrare
			where p.pas=@pas and p.idIntrareFirma is not null


			if @masterPAS=5 --Se ia orice idIntrareFirma si ulterior intrarii (in ultima instanta) cel mai apropiat de momentul intrarii pe FIRMA
			begin
				update #pd set idIntrareFirma=pIntrare.idIntrareFirma,pas=@pas
				from #pd
					cross apply (select top 1 pd1.idPozDoc from #pd pd1 where pd1.idIntrareFirma is not null and 
					pd1.cod=#pd.cod 
						and pd1.data>=#pd.data and pd1.tip_miscare='I' order by pd1.data) pd2 
					inner join #pd pintrare on pd2.idPozDoc=pintrare.idPozDoc
					where #pd.idIntrareFirma is null and (#pd.tip in ('AI','AF') or #pd.tip_miscare='E' and #pd.cantitate<0)

				--Am tratat dupa discutie cu Ghita, ca daca pana la acest pas nu s-a completat idIntrareFirma, atunci idIntrareFirma sa fie egal cu idPozdoc pt. AI sau AE cu cantitate negativa
				update #pd set idIntrareFirma=idPozDoc,pas=@pas
				from #pd
				where #pd.idIntrareFirma is null and (#pd.tip in ('AI','AF') or #pd.tip_miscare='E' and #pd.cantitate<0)
			end
			update #stocuri set idIntrare=idIntrareFirma
			from #pd p
			inner join #stocuri s on s.Subunitate=p.Subunitate and s.Gestiune=p.Gestiune and s.Cod=p.Cod and s.Cod_intrare=p.Cod_intrare
			where p.pas=@pas and p.idIntrareFirma is not null


			select @nrRanduriDeRezolvat=count(*),@nrRanduriDeRezolvatAnterior=0
			from #pd where idIntrareFirma is null

			/*Bucla de transferuri oricate nivele.*/
			while @nrRanduriDeRezolvat>0 and @nrRanduriDeRezolvat<>@nrRanduriDeRezolvatAnterior --ori a rezolvat TOT sau au ramas acelasi numar ca si la pasul anterior adica nu a avut ce rezolva
			begin
	
				/*Punem idintrare la iesiri*/
				update #pd set idIntrareFirma=s.idIntrare,pas=@pas
				from #pd p
				inner join #stocuri s on s.Subunitate=p.Subunitate and s.Gestiune=p.Gestiune and s.Cod=p.Cod and s.Cod_intrare=p.Cod_intrare
				where p.tip_miscare='E' and s.idIntrare is not null and idIntrareFirma is null

				/*Pentru TI-uri*/
				update pti set idIntrareFirma=pte.idIntrareFirma,pas=@pas
				from #pd pte
				inner join #pd pti on pte.idPozDoc=pti.idPozDoc
				where pte.pas=@pas and pte.idIntrareFirma is not null

				update #stocuri set idIntrare=idIntrareFirma
				from #pd p
				inner join #stocuri s on s.Subunitate=p.Subunitate and s.Gestiune=p.Gestiune and s.Cod=p.Cod and s.Cod_intrare=p.Cod_intrare
				where p.pas=@pas and p.idIntrareFirma is not null and p.tip_miscare='I'

				select @nrRanduriDeRezolvatAnterior=@nrRanduriDeRezolvat
				select @nrRanduriDeRezolvat=count(*)
					from #pd where idIntrareFirma is null

				set @pas=@pas+1
			end
			set @masterPAS=@masterPAS+1
		end
	
		alter table pozdoc disable trigger all
		begin transaction modificaremasivapozdoc

		update pozdoc set idIntrareFirma=#pd.idIntrareFirma
		from pozdoc 
		inner join #pd on pozdoc.idPozDoc=#pd.idPozDoc and #pd.tip not in ('TI','PI','DI')
		where #pd.idIntrareFirma is not null and pozdoc.tip not in ('SI','FI','RM','PP')

		update s1 set idIntrareFirma=s2.idIntrare
		from stocuri s1
		inner join #stocuri s2 on s1.Cod_gestiune=s2.gestiune and s1.Cod=s2.cod and s1.Cod_intrare=s2.cod_intrare
		--where s1.Tip_gestiune!='F'	permis si pentru Folosinta update-ul pe stocuri

		update s1 set idIntrareFirma=s2.idIntrare
		from istoricstocuri s1
		inner join #stocuri s2 on s1.Cod_gestiune=s2.gestiune and s1.Cod=s2.cod and s1.Cod_intrare=s2.cod_intrare
		where s1.data_lunii=@dDImpl --and s1.Tip_gestiune!='F'	permis si pentru Folosinta update-ul pe istoricstocuri

		commit transaction modificaremasivapozdoc
		alter table pozdoc enable trigger all
	
		drop table #pd
		drop table #stocuri
		if not exists (select * from par where tip_parametru='GE' and parametru='ADAUGIDIF')
			insert into par (Tip_parametru, Parametru, Denumire_parametru, Val_logica, Val_numerica, Val_alfanumerica) values ('GE','ADAUGIDIF', 'Versiune idIntrareFirma', 0, @versiuneAdaugIntrareFirma, '')
		else
			update par set Val_numerica=@versiuneAdaugIntrareFirma where Tip_parametru='GE' and parametru='ADAUGIDIF'
	end
	if not exists (select 1 from stocuri where idintrare is not null)
	begin
		alter table pozdoc disable trigger all
		begin transaction modificaremasivapozdoc2
			update pozdoc set idIntrare=null
		commit transaction modificaremasivapozdoc2
		alter table pozdoc enable trigger all

		if object_id('tempdb..#stocuriidintrare1') is not null drop table #stocuriidintrare1
		select subunitate,gestiune,cod,cod_intrare,idpozdoc,ROW_NUMBER() over (partition by subunitate,gestiune,cod,cod_intrare order by min(fel),idpozdoc) as ranc
			into #stocuriidintrare1
		from (
		select subunitate,gestiune,cod,cod_intrare,idpozdoc,2 as fel
		from pozdoc where ((cantitate>0 and tip_miscare='I') or (cantitate<0 and tip_miscare='E'))
		union all
		select subunitate,Gestiune_primitoare,cod,(case when grupa='' then cod_intrare else Grupa end),idpozdoc,1 as fel
			from pozdoc where tip in ('TE','PF','DF')) unificate
		group by subunitate,gestiune,cod,cod_intrare,idpozdoc
	
		delete from #stocuriidintrare1 where ranc>1

		update stocuri set idIntrare=p.idPozDoc
			from stocuri
			inner join #stocuriidintrare1 p on stocuri.Cod_gestiune=p.Gestiune and stocuri.Subunitate=p.Subunitate and stocuri.Cod=p.cod and stocuri.Cod_intrare=p.Cod_intrare
			inner join gestiuni g on stocuri.Cod_gestiune=g.Cod_gestiune
			where g.Tip_gestiune!='V' and stocuri.Tip_gestiune!='F'

		update stocuri set idIntrare=p.idPozDoc
			from stocuri
			inner join #stocuriidintrare1 p on stocuri.Cod_gestiune=p.Gestiune and stocuri.Subunitate=p.Subunitate and stocuri.Cod=p.cod and stocuri.Cod_intrare=p.Cod_intrare
			inner join personal pf on stocuri.Cod_gestiune=pf.Marca
			where stocuri.Tip_gestiune='F'

		alter table pozdoc disable trigger all
		begin transaction modificaremasivapozdoc1

		update pozdoc set idIntrare=si.idPozdoc
			from #stocuriidintrare1 si where si.Gestiune=pozdoc.Gestiune and si.Subunitate=pozdoc.Subunitate and si.Cod=pozdoc.cod and si.Cod_intrare=pozdoc.Cod_intrare
	
		commit transaction modificaremasivapozdoc1
		alter table pozdoc enable trigger all
	
		drop table #stocuriidintrare1
	end
	--script care va completa idIntrareTI din pozdoc cu idPozdoc de pe primul TE care a generat pozitia de stoc (subunitate, cod, gestiune, cod_intrare=grupa).
	if not exists (select 1 from pozdoc where idintrareTI is not null)
	begin
		/* caz de TI si TI pe acelasi cod intrare */
		alter table pozdoc disable trigger all
		begin transaction modificaremasivapozdoc3
			update pozdoc set idIntrareTI=null 
		commit transaction modificaremasivapozdoc3
		alter table pozdoc enable trigger all

		if object_id('tempdb..#idintrareTI') is not null drop table #idintrareTI

		select subunitate,gestiune,cod,cod_intrare,idpozdoc,ROW_NUMBER() over (partition by subunitate,gestiune,cod,cod_intrare order by idpozdoc) as ranc
			into #idintrareTI
		from (
			select subunitate,Gestiune_primitoare as gestiune,cod,(case when grupa='' then cod_intrare else Grupa end) as cod_intrare,idpozdoc
			from pozdoc where tip in ('TE','DF','PF')) ti
		group by subunitate,gestiune,cod,cod_intrare,idpozdoc

		delete from #idintrareTI where ranc>1

		alter table pozdoc disable trigger all
		begin transaction modificaremasivapozdoc4

		update pozdoc set idIntrareTI=(case when ti.idPozdoc=pozdoc.idPozdoc then idIntrareTI else ti.idPozdoc end)
			from #idintrareTI ti 
		where pozdoc.Tip in ('TE','DF','PF')
			and ti.Gestiune=pozdoc.Gestiune_primitoare and ti.Subunitate=pozdoc.Subunitate and ti.Cod=pozdoc.cod and ti.Cod_intrare=(case when pozdoc.grupa='' then pozdoc.cod_intrare else pozdoc.Grupa end)

		commit transaction modificaremasivapozdoc4
		alter table pozdoc enable trigger all
	
		if object_id('tempdb..#idintrareTI') is not null drop table #idintrareTI
	end
end try
begin catch
	if @@trancount>0	
		rollback tran
	alter table pozdoc enable trigger all
	declare @mesaj varchar(4000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
end catch

