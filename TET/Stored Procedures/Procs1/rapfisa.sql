--***
create procedure rapfisa @pLm char(20),@pCom char(20),@pNivel int,@pNivelMax int,@pCantPond float,@pArtSup char(20),@pExceptArtSup char(20),@pExcArtNeincl char(20),@pArtInf char(20),@pDetalDOC int,@pSub char(20),@pDinf datetime,@pDsup datetime,@peluni bit,
@pGrCom int,@pComenziNedet char(100),@pArtCalcNedet char(100),@pNrOrd int,@PeConturi int = 0, @cu_tabela int = 0
as    
begin    
	set transaction isolation level read uncommitted
	if exists (select 1 from sysobjects where name='fisacmdttmp' and xtype='U') drop table fisacmdttmp
	create table fisacmdttmp
			(	lunaanalfa char(23),
				[Numar_de_ordine] [int] not NULL,
				[Nivel] [smallint] not NULL,
				[Descriere] [char](100) not NULL,
				[Cantitate] [float] not NULL,
				[Pret] [float] not NULL,
				[Valoare] [float] not NULL,
				[Tip] [char](1) not NULL,
				[Cod] [char](20) not NULL,
				[Locm] [char](9) not NULL,
				[comanda_sup] [char](20) not NULL,
				[art_sup] [char](9) not NULL,
				[NrOrdP] [int] not NULL,
				unic int not null)
 truncate table tmpartc    
 declare @nStrict int    
 if @pCom<>''    
 begin    
  set @nStrict=0    
  insert into tmpartc select ordinea_in_raport,articol_de_calculatie,ordinea_in_raport from artcalc where ordinea_in_raport=0
 end    
 else    
  set @nStrict=1    
 update par set val_logica=@nStrict where tip_parametru='PC' and parametru='STRICTLM'    
 insert into tmpartc select -ordinea_in_raport,articol_de_calculatie,-ordinea_in_raport from artcalc where articol_de_calculatie in ('L','G')    

if (@peluni=1)
	begin
		declare @lunaj datetime,@lunas datetime
		set @lunaj=dbo.BOM(@pDinf)
		while (@lunaj<@pDsup)
		begin
			set @lunas=dbo.eom(@lunaj)
			execute insertfisa @pLm, @pCom, @pNivel, @pNivelMax, @pCantPond, @pArtSup, @pExceptArtSup, @pExcArtNeincl
					,@pArtInf, @pDetalDOC, @pSub, @lunaj, @lunas, @pGrCom, @pComenziNedet, @pArtCalcNedet, @pNrOrd,@PeConturi
			insert fisacmdttmp (lunaanalfa, Numar_de_ordine, Nivel, Descriere, Cantitate, Pret, Valoare, Tip, Cod, Locm, Comanda_sup, Art_sup, NrOrdP, unic)
				select rtrim(c.lunaalfa)+' '+convert(char(4),c.an) as lunaanalfa, Numar_de_ordine, Nivel, Descriere, Cantitate, Pret, Valoare, Tip, Cod, Locm, Comanda_sup, Art_sup, NrOrdP, unic 
				from fisacmdtmp f, fcalendar(@lunaj,@lunaj) c --where c.data=@lunaj
				where Descriere is not null
			--insert fisacmdttmp select @lunaj as luna,* from fisacmdtmp
			set @lunaj=dateadd(m,1,@lunaj)
		end
	end
else
	begin
		execute insertfisa @pLm, @pCom, @pNivel, @pNivelMax, @pCantPond, @pArtSup, @pExceptArtSup, @pExcArtNeincl
		, @pArtInf, @pDetalDOC, @pSub, @pDinf, @pDsup, @pGrCom, @pComenziNedet, @pArtCalcNedet, @pNrOrd,@PeConturi
		insert fisacmdttmp (lunaanalfa, Numar_de_ordine, Nivel, Descriere, Cantitate, Pret, Valoare, Tip, Cod, Locm, Comanda_sup, Art_sup, NrOrdP, unic)
			select convert(char(10),@pDinf,103)+' - '+convert(char(10),@pDsup,103) as lunaanalfa, Numar_de_ordine, Nivel, Descriere, Cantitate, Pret, Valoare, Tip, Cod, Locm, Comanda_sup, Art_sup, NrOrdP, unic  
			from fisacmdtmp f
			where Descriere is not null
	end
/*
 execute insertfisa @pLm, @pCom, @pNivel, @pNivelMax, @pCantPond, @pArtSup, '*','*' , @pArtInf, @pDetalDOC, @pSub, @pDinf, @pDsup, @pGrCom, @pComenziNedet, @pArtCalcNedet, @pNrOrd,@PeConturi
 select * from fisacmdtmp    */
if (@cu_tabela=0)  
	begin 
			select * from fisacmdttmp 
			drop table fisacmdttmp  
	end
end
