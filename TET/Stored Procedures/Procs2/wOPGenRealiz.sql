--***
create procedure  wOPGenRealiz  @sesiune varchar(50), @parXML xml 
as
begin try 
 declare @datajos datetime , @datasus datetime,@cantitate float , @termen datetime, @contract varchar(20),@tip varchar(2),@TermPeSurse int,
		 @cod varchar(20), @data datetime, @tert varchar(20), @utilizator varchar(50)
 exec luare_date_par 'UC', 'POZSURSE', @TermPeSurse output, 0, ''
 exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
 set @datajos=isnull(@parXML.value('(/parametri/@datajos)[1]','datetime'),'01/01/1901')
 set @datasus=isnull(@parXML.value('(/parametri/@datasus)[1]','datetime'),'01/01/1901')
 declare @fltLmUt int	
 select @fltLmUt=isnull((select count(1) from LMFiltrare),0)
 declare genterm cursor for 
 select t.tip,t.termen, t.cantitate,t.tert,t.data, c.contract, t.cod from termene t 
    inner join pozcon p on p.subunitate=t.subunitate and p.tert=t.tert and p.contract=t.contract 
    and t.cod=(case when @TermPeSurse=0 then p.cod else ltrim(str(p.numar_pozitie)) end)
    inner join con c on t.subunitate=c.subunitate and t.tert=c.tert and t.contract=c.contract and t.data=c.data
    where t.tip='BF' and t.termen between @datajos and @datasus and c.stare='1'and t.cant_realizata=0
     and (dbo.f_areLMFiltru(@utilizator)=0 or exists(select (1) from LMFiltrare pr where pr.utilizator=@utilizator and pr.cod=c.Loc_de_munca)) 
 open genterm 
	fetch next from genterm into @tip, @termen, @cantitate,@tert, @data, @contract, @cod
		while @@FETCH_STATUS=0
			begin 
			update termene set Val2='1', Val1=@cantitate where Contract=@contract and termen=@termen and tert=@tert and data=@data and cod=@cod
	fetch next from genterm into @tip, @termen, @cantitate,@tert, @data, @contract, @cod
 end
 close genterm
 deallocate genterm
 select 'Generare realizari efectuata cu succes!' as textMesaj for xml raw, root('Mesaje')
end try
 
begin catch
 declare @eroare varchar(200) 
	set @eroare=ERROR_MESSAGE()
	raiserror(@eroare, 16, 1) 
end catch


