--***
create function fFiltrareAutomata (@filtru varchar(20),@tipfiltru char(20))
returns varchar(200)
as begin
--@tipfiltru - ce camp e filtrat, locm=loc de munca
--@filtru - daca in afara de filtrarae automata, mai este si filtru in raport, valoarea din raport
declare @resultat varchar(200),@utilizator char(20),@cod varchar(20),@denumire varchar(50),@i int
select @resultat='',@utilizator='',@cod='',@denumire='',@i=0
select @utilizator=dbo.fIaUtilizator(null) 
if @tipfiltru='locm'
begin 
	if isnull(@filtru,'')<>'' 
		if dbo.f_areLMFiltru(@utilizator)=0
			if not exists (select 1 from lm where lm.Cod=@filtru) set @resultat='Locul de munca ales ('+rtrim(@filtru)+') nu exista!'
			else set @resultat='Loc de munca: '+RTRIM(@filtru)+' - '+rtrim((select denumire from lm where cod=@filtru))
		else
			if not ISNULL((select COUNT(1) from LMFiltrare where utilizator=@utilizator and cod=@filtru),0)>0
				set @resultat='Locul de munca ales nu se regaseste in lista de locuri de munca pe care aveti acces!'
			else
				set @resultat='Loc de munca: '+RTRIM(@filtru)+' - '+rtrim((select denumire from lm where cod=@filtru))
	else
		if isnull((SELECT COUNT(1) FROM proprietati WHERE Cod_proprietate='LOCMUNCA' and tip='UTILIZATOR' and cod=@utilizator and valoare<>'') ,0)>0
		begin
			set @resultat='Loc de munca: '
			Declare crslm cursor for
			select a.valoare,b.denumire
			from  proprietati a
			inner join lm b on b.cod=a.valoare 
			WHERE a.Cod_proprietate='LOCMUNCA' and a.tip='UTILIZATOR' and a.cod=@utilizator and a.valoare<>''
			Order by a.valoare
			Open crslm
			Fetch next from crslm into @cod,@denumire 
			While (@@fetch_status = 0  )
			begin
				set @resultat=@resultat+(case when @i>0 then ',' else '' end)+' '+RTRIM(@cod)+'-'+RTRIM(@denumire)
				Fetch next from crslm into @cod,@denumire 
				set @i=@i+1
			End
		Close crslm
		Deallocate crslm
	end
end		



return @resultat

end
