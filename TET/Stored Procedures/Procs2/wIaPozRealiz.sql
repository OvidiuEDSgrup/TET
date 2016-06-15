--***
create procedure [dbo].[wIaPozRealiz] @sesiune varchar(50), @parXML xml 
as  

declare @subunitate varchar(20), @userASiS varchar(20), @iDoc int,@lCuTermene int ,@lista_clienti bit, @f_contract varchar(20),@tert varchar(13),
    @tipDoc varchar (2), @numar varchar(20), @data datetime , @data_jos datetime , @data_sus datetime, @fcontract varchar(20), @beneficiar varchar(80),
    @fstare varchar(80) , @valoare_minima varchar (80), @valoare_maxima varchar(80),@dencontract varchar(90),@fbeneficiar varchar(80),@fdenumire varchar(80),
    @fsursa varchar(80),@lista_gestiuni bit ,@realizat varchar(1),@facturat varchar(1),@nefacturat varchar(1), @TermPeSurse int,@flocmunca varchar(20), 
    @Periodicitate int, @stare varchar(10),@cautare varchar(20)
    
exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
select @lista_gestiuni=0, @lista_clienti=0
select @lista_gestiuni=(case when cod_proprietate='GESTIUNE' then 1 else @lista_gestiuni end), 
		   @lista_clienti=(case when cod_proprietate='CLIENT' then 1 else @lista_clienti end)
from proprietati 
where tip='UTILIZATOR' and cod=@userASiS and cod_proprietate in ('GESTIUNE', 'CLIENT') and valoare<>''
select @subunitate=val_alfanumerica from par where tip_parametru='GE' and parametru='SUBPRO'                              
select @lCuTermene=Val_logica from par where tip_parametru='UC' and parametru='TERMCNTR'
exec luare_date_par 'UC', 'POZSURSE', @TermPeSurse output, 0, ''
exec luare_date_par 'UC', 'PERIODCON', @Periodicitate output, 0, ''


select 	 @numar=isnull(@parXML.value('(/row/@numar)[1]','varchar(20)'),''),
		 @data=isnull(@parXML.value('(/row/@data)[1]','datetime'),'1901-01-01'),
		 @data_jos=isnull(@parXML.value('(/row/@datajos)[1]','datetime'),'1901-01-01'),
		 @data_sus=isnull(@parXML.value('(/row/@datasus)[1]','datetime'),'2901-01-01'),
		 @tipDoc=isnull(@parXML.value('(/row/@tipDoc)[1]','varchar(2)'),''),
		 @tert=isnull(@parXML.value('(/row/@tert)[1]','varchar(13)'),''),
		 @cautare=ISNULL(@parXML.value('(/row/@_cautare)[1]', 'varchar(100)'), ''),
		 @stare=isnull(@parXML.value('(/row/@stare)[1]','varchar(10)'),'')

--select @numar,@data,@tip,@tert,@data_jos, @data_sus
select 	rtrim(t.subunitate) as subunitate ,
		RTRIM(t.tert) as tert, 
		convert(varchar(10),t.data,101)as data, 
		rtrim(t.cod) as cod,
		RTRIM(t.tip)as tip,
		rtrim(t.contract) as contract,
		convert(varchar(10),t.termen,101) as termen, 
		convert(decimal(17, 5), t.pret) as pret, 
		convert(decimal(17, 5), t.cantitate) as planificat, 
		convert(decimal(17, 5), t.cant_realizata) as facturat, 
		convert(decimal(17, 5), t.Val1) as realizat,
		isnull(convert(char(10),SUBSTRING(t.Explicatii,1,10),101),'') as data_pv,
		rtrim(substring(t.explicatii,12,19)) as proces_verbal,
		rtrim(SUBSTRING(explicatii,31,170)) as explicatii,
		(case when (t.cant_realizata<>0 or t.val2=1 and t.val1=0) then 'P' when t.Val2=1 then 'R' else 'N' end) as stare,
		(case when (t.cant_realizata<>0 or t.val2=1 and t.val1=0) then '#808080' when t.Val2=1 then 'Green' else 'Black' end) as culoare,
		--(case when Val1='0' then '0' else '1'end) as factureaza,
		(select convert(decimal(15,2),convert(decimal(15,2),achitat)/(select count(*) from termene tr where tr.explicatii=f.factura and tr.data2=f.data)) 
			from facturi f where f.tip='F' and f.Factura=t.Explicatii and f.data=t.Data2 and f.tert=@tert) as achitat

	into #termene
	from termene t
	where t.Tip=@tipDoc 
		and t.Contract=@numar
		and t.Data=@data
		and t.Tert=@tert 
		and t.Termen between @data_jos and @data_sus
		

		--and charindex((case when (t.cant_realizata<>0 or t.val2=1 and t.val1=0) then 'F' when t.Val2=1 then 'R' else 'N' end),@fstare)>0 --like @fstare+'%'
	
	select	t.subunitate,t.tert as tert,t.data,(case when @TermPeSurse=0 then pz.cod else ltrim(str(pz.numar_pozitie)) end) as cod,t.contract,t.termen,t.pret,t.planificat,t.facturat,t.realizat,t.stare,t.culoare,'('+RTRIM(n.Cod)+')-'+RTRIM(n.Denumire) as denCod, 
			'('+RTRIM(s.Cod)+')-'+isnull(RTRIM(s.Denumire),'') as denSursa,rtrim(s.Cod) as sursa, 'RK' as subtip ,  t.tip as tipDoc ,t.realizat as realizare,
			convert(char(10),t.data_pv,101)as data_pv,t.proces_verbal,t.explicatii,/*t.factureaza,*/t.achitat  
	from #termene t
		left outer join pozcon pz on pz.Subunitate=t.subunitate and pz.Tert=t.tert and pz.Contract=t.contract and pz.data=t.data and pz.tip=@tipDoc
														   and t.cod=(case when @TermPeSurse=0 then pz.cod else ltrim(str(pz.numar_pozitie)) end)
		left outer join nomencl n on n.Cod=pz.Cod 
		left outer join surse s on s.Cod=pz.Mod_de_plata
	where (pz.cod like @cautare+'%' or pz.Mod_de_plata like @cautare+'%' or ISNULL(@cautare,'')='')
	--order by 'Contract '+rtrim(t.contract)+' - '+beneficiar
for xml raw
