--***
create procedure [bkp_validareNecorelatiiStocuri] @Subunitate varchar(20),@Tip varchar(2),@Numar varchar(20),@Data datetime,@Numar_pozitie int,
	@Tip_miscare varchar(2),@Cantitate float,@Gest varchar(13),@Cod varchar(20),@Cod_intrare varchar(13),@Tip_gest varchar(1),
	@Pret_stoc float, @Cont_stoc varchar(40)
as
	/*
		La orice document de tip I,E sa avem corelatie intre stoc si pozdoc
			Pt. set (gestiune,cod,cod_intrare) trebuie sa am aceleasi: pret_stoc, cont_stoc, pret_amanunt (A)
		Sugestie:
			Evaluez posibilitatea unei diferente din cele de mai sus
			Daca este o intrare si anume cea care a creat stocul: sa propage noile valori
			altfel sa dea eroare
				
	*/
	declare @mediup int,@mesajeroare varchar(250)
	set @mediup=isnull((select top 1 val_logica from par where tip_parametru='GE' and parametru='MEDIUP'),0)
	
	if @mediup=1
		return		

	--if @Tip='TE'
	--	set @Tip_miscare='E'	
	if @Tip='TE' and @Tip_miscare='I'
		set @Tip='TI'	
 	
	/*Conditia de necorelatie*/
	if exists (select 1 from stocuri s where s.subunitate=@Subunitate and s.cod=@cod and s.Tip_gestiune=@Tip_gest and s.cod_gestiune=@Gest 
			and s.cod_intrare=@cod_intrare
			and (abs(s.Stoc_initial)>0.01 or abs(s.intrari)>0.01 or abs(s.iesiri)>0.01)
			and ((abs(convert(decimal(17,5),s.Pret)-convert(decimal(17,5),@Pret_stoc))>=0.00001) or ((s.cont<>@Cont_stoc and @Cont_stoc<>'')))) --daca pretul de stoc sau contul de stoc difera
	begin
		if @Tip_miscare='I' --and @Tip not in ('AI','TI') -- la AI/TI nu vreau sa se propage cont/pret, ci sa se faca validare normala... vezi mai jos
			and exists (select 1 from stocuri s where s.subunitate=@Subunitate and s.Tip_gestiune=@Tip_gest and s.cod_gestiune=@Gest 
				and	s.cod=@Cod and s.cod_intrare=@Cod_intrare
				and s.stoc_initial = 0 
				and (@Tip not in ('AI','TI') or s.intrari = @Cantitate)) -- sa se poata modifica si la AI/TI, doar daca cantitatea este egala cu total intrari pe stoc (daca nu este o corectie partiala) 
				--and @Cantitate>0 /*Nu inteleg de ce trebuie doar la cantitate pozitiva*/
			and exists (select * from sysobjects where name ='inlocuirePretsauContpePozDoc') 
			begin /*Daca sunt pe intrare si intrarea respectiva a generat stocul...*/
					--declare @msgErr1 varchar(8000)
					--set @msgErr1='PP - Cod:'+rtrim(@cod)+' Codi:'+@Cod_intrare+'Cont document:'+@Cont_stoc+', Pret stoc document: '+ltrim(str(@pret_stoc,12,2))
					--raiserror (@msgErr1,16,1)
					exec inlocuirePretsauContpePozDoc @subunitate=@Subunitate,@tip=@Tip,@Numar=@numar,@Data=@Data,@Numar_pozitie=@numar_pozitie--, @tipGest=@Tip_gest	
					return
			end
		declare @msgErr varchar(8000)
		set @msgErr='ValidareNecorelatiiStocuri: Documentul ar genera necorelatii! Doc:'+@Tip+' '+@Numar+' '+convert(char(10),@Data,103)+' Gest:'+@Gest+' Cod:'+@cod+' Codi:'+@Cod_intrare+'Cont doc:'+@Cont_stoc+', Pret doc: '+ltrim(str(@pret_stoc,12,2))
		raiserror (@msgErr,16,1)
	end
