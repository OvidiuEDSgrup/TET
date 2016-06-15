create procedure [dbo].[wOPGenComendaMultipla] @sesiune varchar(50), @parXML XML  
as
	set nocount on
	set transaction isolation level READ UNCOMMITTED

begin try -- folositi try/catch pentru a opri firul de executie a procedurii, daca au fost erori.
	declare	
		@fltDenumire varchar(80), @fltCod varchar(20), @necesarJos float, @necesarSus float ,@dataJos datetime, @dataSus datetime,
		@comenzi XML, @aux xml,@flttip varchar(20),@parXML2 xml		,@dataLans datetime,@numarDoc int, @cantitateM float, @codM varchar(20),@par xml,
		@contract varchar(20),@tert varchar(20),@gestiune varchar(20),@cont varchar(20)
				
		
		declare @utilizator varchar(20)		
		exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
		
		set @parXML2=(select top 1 valoare from parSesiuniRIA where username=@utilizator and param='FLTFLANS')
		
		set @fltDenumire='%'+REPLACE(isnull((@parXML2.value('(/row/@f_denumire)[1]', 'varchar(80)')),'%'),' ','%')+'%'
		set @fltCod='%'+REPLACE(isnull((@parXML2.value('(/row/@f_cod)[1]', 'varchar(80)')),'%'),' ','%')+'%'
		set @necesarJos=isnull((@parXML2.value('(/row/@f_necesarJos)[1]', 'float')),0.000001)
		set @fltTip=isnull((@parXML2.value('(/row/@f_tip)[1]', 'varchar(20)')),'%')
		set @necesarSus=isnull((@parXML2.value('(/row/@f_necesarSus)[1]', 'float')),9999999)
		set @dataJos= isnull((@parXML2.value('(/row/@datajos)[1]', 'datetime')),'01/01/1990')
		set @dataSus= isnull((@parXML2.value('(/row/@datasus)[1]', 'datetime')),'01/01/2100')
		
		
		set @dataLans=@parXML.value('(/parametri/@data)[1]', 'datetime')
		declare @subunitate varchar(20)
		select top 1 @subunitate=val_alfanumerica from par where Tip_parametru='GE' and Parametru='SUBPRO'
		set @subunitate=ISNULL(@subunitate,'1')
		
		declare @nrComenziProd int,@nrComenziSemi int
		select tert,contract,comanda,cod,SUM(cantitate) as cantitate,min(termen) as termen
		into #tmpComenziProd
		from tmpFundamentareLansare 
			where sesiune=@sesiune
			group by cod,contract,tert,comanda
			order by cod,contract,tert,comanda
			
		select @nrComenziProd=COUNT(*) from 
			#tmpComenziProd
	
		if @nrComenziProd>0 --Facem lansare pentru comenzi de productie
		begin
			declare @serie varchar(2),@nrComanda int,@idplaja int
			declare @primacomanda varchar(20),@ultimacomanda varchar(20)
			--Nu voi folosi iaNrDocFiscale
			--Vom face (momentan) o singura plaja pe loc de munca
			
			select top 1 @idplaja=id,@serie=serie,@nrcomanda=UltimulNr from docfiscale where TipDoc='LP'
			
			if @nrComanda is null
				raiserror('Nu aveti alocata nicio plaja de comenzi',11,1)
			update docfiscale set UltimulNr=UltimulNr+@nrComenziProd where id=@idplaja
			set @primacomanda=ltrim(rtrim(@serie))+ltrim(str(@nrComanda+1))
			set @ultimacomanda=ltrim(rtrim(@serie))+LTRIM(str(@nrcomanda+@nrcomenziprod))
			
			if exists(select 1 from comenzi where LEN(comanda)=LEN(@primacomanda) and 
				Comanda between @primacomanda and @ultimacomanda)
			begin
				declare @msge varchar(1000)
				set @msge='Exista comanda in tabela de comenzi intre:'+@primacomanda+' si '+@ultimacomanda
				raiserror(@msge,11,1)
			end

			insert into comenzi(Subunitate,Comanda,
			Tip_comanda,Descriere,Data_lansarii,Data_inchiderii,Starea_comenzii,
			Grup_de_comenzi,Loc_de_munca,Numar_de_inventar,
			Beneficiar,Loc_de_munca_beneficiar,Comanda_beneficiar,Art_calc_benef)
				select @subunitate,rtrim(@serie)+ltrim(str(@nrComanda+ROW_NUMBER() 
					over (order by cp.cod,cp.contract,cp.tert))) 
					as comanda,
				'P',max(n.Denumire),@dataLans,@dataLans,'L' as starea_comenzii,
				0 as grup_de_comenzi,'' as loc_de_munca,CONVERT(varchar(10),min(cp.termen),103) as numar_de_inventar,
					isnull(cp.tert,'') as beneficiar,'' as loc_de_munca_beneficiar,'' as Comanda_beneficiar,'' as art_calc_benef
				from #tmpComenziProd cp
				inner join nomencl n on cp.cod=n.cod
				inner join pozTehnologii pt on pt.tip='T' and pt.cod=cp.cod	
				group by cp.cod,cp.contract,cp.tert
				order by cp.cod,cp.contract,cp.tert
			
			insert into dependentelans(comanda,cod,tert,contract,comandaleg)
				select rtrim(@serie)+ltrim(str(@nrComanda+DENSE_RANK() 
					over (order by cp.cod,cp.contract,cp.tert))),
				cp.cod,cp.tert,cp.contract,cp.comanda
			from #tmpComenziProd cp 
			inner join nomencl n on cp.cod=n.cod
			inner join pozTehnologii pt on pt.tip='T' and pt.cod=cp.cod	
			order by cp.cod,cp.contract,cp.tert
			
			declare @randuriafectate int,@nivel int
			set @nivel=0
			create table #parinti(nivel int,id int,idp int,idorig int,parinteTop int,cantitate float)

			--Mergem pe modelul parinte - fii (seturi de date)
			
			insert into pozTehnologii(tip,cod,cantitate,pret,resursa,idp)
			output 0,inserted.id,inserted.idp,inserted.idp,inserted.id,inserted.cantitate into #parinti
			select 'L',rtrim(@serie)+ltrim(str(@nrComanda+ROW_NUMBER() 
				over (order by cp.cod,cp.contract))),
			sum(cp.cantitate),min(pt.id),'',min(pt.id)
			from #tmpComenziProd cp
			inner join nomencl n on cp.cod=n.cod
			inner join pozTehnologii pt on pt.tip='T' and pt.cod=cp.cod
			group by cp.cod,cp.contract,cp.tert

			update pozTehnologii set parinteTop=pozTehnologii.id 
			from #parinti where #parinti.id=pozTehnologii.id
			
			set @randuriafectate=@@ROWCOUNT --Pentru a intra in bucla							

			while @randuriafectate>0
			begin
				insert into pozTehnologii(tip,cod,cantitate,pret,resursa,idp,parinteTop)
				output @nivel+1,inserted.id,inserted.idp,inserted.pret,0,inserted.cantitate into #parinti
				select fii.tip,fii.cod,fii.cantitate*ptp.cantitate as cantitate,fii.id,fii.resursa,ptp.id,ptp.parinteTop
				from pozTehnologii fii
				inner join #parinti ptp on ptp.idorig=fii.idp and ptp.nivel=@nivel
				where fii.tip not in ('L','A')
			
				set @randuriafectate=@@ROWCOUNT
				set @nivel=@nivel+1
				
				/*La randurile tocmai inserate facem update parinteTop*/
				update pozTehnologii set parinteTop=parinte.parinteTop
				from pozTehnologii
				inner join #parinti ptp on ptp.id=pozTehnologii.id and ptp.nivel=@nivel
				inner join pozTehnologii parinte on pozTehnologii.idp=parinte.id
			end
			
			drop table #tmpComenziProd
			return
		end
		--Pentru lansare semifabricate
		
		return
		select @nrComenziSemi=COUNT(distinct cod) from tmpFundamentareLansare 
			where sesiune=@sesiune and comanda is not null

end try
begin catch
	declare @mesaj varchar(1000)
	set @mesaj = '(wOPGenComandaMultipla)'+ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)
end catch
