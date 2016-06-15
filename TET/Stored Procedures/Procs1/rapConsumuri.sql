--***

create procedure rapConsumuri (@sesiune varchar(50)='', @datajos datetime, @datasus datetime,
	@tip varchar(100)=',CM,DF,',
	@gestiune varchar(100)=null,
	@cod varchar(100)=null,
	@lm varchar(100)=null,
	@comanda varchar(100)=null,
	@ordonare varchar(100)='G',
	@locatie varchar(200)=null)
as
set transaction isolation level read uncommitted
declare @eroare varchar(max)
select @eroare=''
begin try

	/**	Pregatire filtrare pe proprietati utilizatori*/
		declare @eLmUtiliz int,@eGestUtiliz int
		declare @LmUtiliz table(valoare varchar(200), cod_proprietate varchar(20))
		declare @GestUtiliz table(valoare varchar(200), cod_proprietate varchar(20))

		insert into @LmUtiliz(valoare, cod_proprietate)
		select valoare, cod_proprietate from fPropUtiliz(@sesiune) where valoare<>'' and cod_proprietate='LOCMUNCA'
		set @eLmUtiliz=isnull((select max(1) from @LmUtiliz),0)
		insert into @GestUtiliz(valoare, cod_proprietate)
		select valoare, cod_proprietate from fPropUtiliz(@sesiune) where valoare<>'' and cod_proprietate='GESTIUNE'
		set @eGestUtiliz=isnull((select max(1) from @GestUtiliz),0)

	select a.tip,rtrim(a.gestiune) as gestiune,rtrim(g.denumire_gestiune) as denumire_gestiune, rtrim(a.numar) as numar,left(convert(char(10),data,104),10) as data, 
		rtrim(a.loc_de_munca) as loc_de_munca, rtrim(a.comanda) as comanda, rtrim(a.cod) as cod, rtrim(b.denumire) as denumire,
		a.cantitate, a.pret_de_stoc, rtrim(a.cont_de_stoc) as cont_de_stoc, rtrim(a.cont_corespondent) as cont_corespondent, isnull(c.descriere,'') as descriere 
	from nomencl b, gestiuni g, pozdoc a 
		left outer join comenzi c on a.comanda=c.comanda and a.subunitate=c.subunitate
	where charindex(','+a.tip+',',@Tip)>0 and a.cod=b.cod and a.gestiune=g.cod_gestiune and a.subunitate=g.subunitate and (@gestiune is null or a.gestiune=@gestiune)
		and (@cod is null or a.cod=@cod) and (@lm is null or a.loc_de_munca like rtrim(@lm)+'%') and (@comanda is null or a.comanda=@comanda)
		and data between @DataJos and @DataSus
		and (@locatie is null or a.locatie=@locatie)
		and (@eLmUtiliz=0 or exists (select 1 from @LmUtiliz u where u.valoare=a.Loc_de_munca))
		and (@eGestUtiliz=0 or exists (select 1 from @GestUtiliz u where u.valoare=a.Gestiune))
	order by (case when @Ordonare='G' then a.gestiune else a.comanda end), substring(a.cod,1,2), a.numar, a.numar_pozitie

end try
begin catch
	select @eroare=error_message()+' (' + OBJECT_NAME(@@PROCID) + ')'
end catch

if len(@eroare)>0
select '<EROARE>' as gestiune, @eroare as denumire
