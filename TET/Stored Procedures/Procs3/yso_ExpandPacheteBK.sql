CREATE PROCEDURE yso_ExpandPacheteBK @sub CHAR(9), @tip CHAR(2), @contract CHAR(20), @data DATETIME, @tert CHAR(13) AS

--DECLARE @sub CHAR(9), @tip CHAR(2), @contract CHAR(20), @data DATETIME, @tert CHAR(13)
--SELECT TOP 1 
--@Sub='1'
--,@tip='BK'
--,@contract=Contract
--,@tert=Tert
--,@data=data
--FROM pozcon where tip='bk' and Contract='9810013'

if 0<
(select COUNT(*) from pozcon pp 
		join con c on c.Subunitate=pp.Subunitate and c.Tip=pp.Tip and c.Contract=pp.Contract and c.Data=pp.Data and c.Tert=pp.Tert
		join tehn t on t.Cod_tehn=pp.Cod
	where pp.Subunitate=@sub and pp.Tip=@tip and pp.Contract=@contract and pp.Data=@data and pp.Tert=@tert and c.Mod_plata<>'1'
	and not exists
	(select 1 from pozcon pc 
	inner join con c on c.Subunitate=pc.Subunitate and c.Tip=pc.Tip and c.Contract=pc.Contract and c.Data=pc.Data and c.Tert=pc.Tert
	where c.Subunitate=pp.Subunitate and c.Tip=pp.Tip and c.Data=pp.Data and c.Tert=pp.Tert
		and c.Contract=RTRIM(pp.Contract)+'.'+RTRIM(pp.numar_pozitie) 
		/*and c.Contract_coresp=pp.Cod and c.Mod_plata='1'*/))
begin
	insert pozcon
	select --*,
	pp.Subunitate	--Subunitate	char	9
	,pp.tip	--Tip	char	2
	,RTRIM(pp.Contract)+'.'+RTRIM(pp.numar_pozitie)	--Contract	char	20
	,pp.Tert	--Tert	char	13
	,pp.Punct_livrare	--Punct_livrare	char	13
	,pp.Data	--Data	datetime	8
	,tp.Cod	--Cod	char	20
	,tp.Specific	--Cantitate	float	8
	,0	--Pret	float	8
	,0	--Pret_promotional	float	8
	,0	--Discount	real	4
	,pp.Termen	--Termen	datetime	8
	,pp.Factura	--Factura	char	20
	,0	--Cant_disponibila	float	8
	,tp.Specific	--Cant_aprobata	float	8
	,0	--Cant_realizata	float	8
	,''	--Valuta	char	3
	,24	--Cota_TVA	real	4
	,0	--Suma_TVA	float	8
	,''	--Mod_de_plata	char	8
	,''	--UM	char	1
	,0	--Zi_scadenta_din_luna	smallint	2
	,''	--Explicatii	char	200
	,tp.Nr	--Numar_pozitie	int	4
	,pp.Utilizator	--Utilizator	char	10
	,GETDATE()	--Data_operarii	datetime	8
	,''	--Ora_operarii	char	6 
	from tehnpoz tp join pozcon pp on tp.Cod_tehn=pp.Cod and tp.Tip='M' and tp.Loc_munca=''
	where pp.Subunitate=@sub and pp.Tip=@tip and pp.Contract=@contract and pp.Data=@data and pp.Tert=@tert
	and not exists 	
	(select 1 from pozcon pc 
	inner join con c on c.Subunitate=pc.Subunitate and c.Tip=pc.Tip and c.Contract=pc.Contract and c.Data=pc.Data and c.Tert=pc.Tert
	where c.Subunitate=pp.Subunitate and c.Tip=pp.Tip and c.Data=pp.Data and c.Tert=pp.Tert
		and c.Contract=RTRIM(pp.Contract)+'.'+RTRIM(pp.numar_pozitie) 
		and pc.Cod=tp.Cod and pc.Numar_pozitie=tp.Nr /*and c.Contract_coresp=pp.Cod and c.Mod_plata='1'*/)

	insert con
	select --*,
	c.Subunitate	--Subunitate	char	9
	,c.tip	--Tip	char	2
	,RTRIM(pp.Contract)+'.'+RTRIM(pp.numar_pozitie)	--Contract	char	20
	,c.Tert	--Tert	char	13
	,c.Punct_livrare	--Punct_livrare	char	13
	,c.Data	--Data	datetime	8
	,'0'	--Stare	char	1
	,c.Loc_de_munca	--Loc_de_munca	char	9
	,c.Gestiune	--Gestiune	char	9
	,c.Termen	--Termen	datetime	8
	,c.Scadenta	--Scadenta	smallint	2
	,c.Discount	--Discount	real	4
	,c.Valuta	--Valuta	char	3
	,c.Curs	--Curs	float	8
	,'1'	--Mod_plata	char	1
	,c.Mod_ambalare	--Mod_ambalare	char	1
	,c.Factura	--Factura	char	20
	,0	--Total_contractat	float	8
	,0	--Total_TVA	float	8
	,pp.Cod	--Contract_coresp	char	20
	,''	--Mod_penalizare	char	13
	,0	--Procent_penalizare	real	4
	,0	--Procent_avans	real	4
	,0	--Avans	float	8
	,0	--Nr_rate	smallint	2
	,0	--Val_reziduala	float	8
	,0	--Sold_initial	float	8
	,''	--Cod_dobanda	char	20
	,0	--Dobanda	real	4
	,0	--Incasat	float	8
	,''	--Responsabil	char	20
	,''	--Responsabil_tert	char	20
	,''	--Explicatii	char	50
	,''	--Data_rezilierii	datetime	8
	from pozcon pp
		join con c on c.Subunitate=pp.Subunitate and c.Tip=pp.Tip and c.Contract=pp.Contract and c.Data=pp.Data and c.Tert=pp.Tert
		join tehn t on t.Cod_tehn=pp.Cod
	where pp.Subunitate=@sub and pp.Tip=@tip and pp.Contract=@contract and pp.Data=@data and pp.Tert=@tert
		/*and not exists
		(select 1 from con c where c.Subunitate=pp.Subunitate and c.Tip=pp.Tip and c.Data=pp.Data and c.Tert=pp.Tert
			and c.Contract=RTRIM(pp.Contract)+'.'+REPLICATE('0',3-LEN(pp.numar_pozitie))+RTRIM(pp.numar_pozitie) 
		and c.Contract_coresp=pp.Cod and c.Mod_plata='1')*/
end

declare componente cursor for
select distinct cc.Subunitate,cc.Tip,cc.Contract,cc.Data,cc.Tert from pozcon pc 
	inner join con cc on cc.Subunitate=pc.Subunitate and cc.Tip=pc.Tip and cc.Contract=pc.Contract and cc.Data=pc.Data and cc.Tert=pc.Tert
	inner join pozcon pp on cc.Subunitate=pp.Subunitate and cc.Tip=pp.Tip and cc.Data=pp.Data and cc.Tert=pp.Tert
		and cc.Contract=RTRIM(pp.Contract)+'.'+RTRIM(pp.numar_pozitie)
	inner join con cp on cp.Subunitate=pp.Subunitate and cp.Tip=pp.Tip and cp.Contract=pp.Contract and cp.Data=pp.Data and cp.Tert=pp.Tert
	where pp.Subunitate=@sub and pp.Tip=@tip and pp.Contract=@contract and pp.Data=@data and pp.Tert=@tert
		and cc.Contract_coresp=pp.Cod and cc.Mod_plata='1' 
	
open componente
fetch next from componente into @sub,@tip,@contract,@data,@tert
while @@FETCH_STATUS=0
begin
	exec yso.DefalcTermeneBK @subunitate=@sub, @tip=@tip, @contract=@contract,@data=@data,@tert=@tert
end

close componente
deallocate componente