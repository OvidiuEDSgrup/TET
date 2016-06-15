create procedure validConcedii
as
begin try	
	declare @userASiS varchar(50), @mesajeroare varchar(1000)
	set @userASiS=dbo.fIaUtilizator(null)

	if exists (select 1 from #concedii i where i.Tip_concediu='' and i.fel<>'CM')
		raiserror('Tip concediu necompletat!',16,1)

	if exists (select 1 from #concedii i where dbo.eom(i.Data_inceput)<>dbo.eom(i.Data) and i.fel<>'CM')
	begin
		select @mesajeroare='Eroare operare '+rtrim(nume_tabela)+': Data de inceput trebuie sa fie in luna de lucru!'
		from #concedii i where dbo.eom(i.Data_inceput)<>dbo.eom(i.Data)	
		raiserror(@mesajeroare,16,1)
	end

	if exists (select 1 from #concedii i where Data_inceput>Data_sfarsit)
	begin
		select @mesajeroare='Eroare operare '+rtrim(c.nume_tabela)+': Data de sfarsit nu poate fi mai mica decat data de inceput (salariatul '+rtrim(p.nume)+' - '+rtrim(c.marca)+') !'
		from #concedii c
		left outer join personal p on p.Marca=c.Marca
		where c.Data_inceput>c.Data_sfarsit
		raiserror(@mesajeroare,16,1)
	end

--	validare suprapunere cu concedii\alte
	if exists (select 1 from conalte ca 
			inner join #concedii i on ca.Marca=i.Marca and ca.Data=i.Data
		where charindex(ca.Tip_concediu,'5ABCDEN')=0
			and (i.fel<>'CA' or ca.Data_inceput<>i.Data_inceput)
			and (i.Data_inceput between ca.Data_inceput and ca.Data_sfarsit or i.Data_sfarsit between ca.Data_inceput and ca.Data_sfarsit
			or ca.Data_inceput between i.Data_inceput and i.Data_sfarsit))
	begin
		select @mesajeroare='Eroare operare '+rtrim(nume_tabela)+': Exista date in concedii\alte in luna, care se suprapun cu aceasta perioada (salariatul '+rtrim(p.nume)+' - '+rtrim(ca.marca)+') !'
		from conalte ca 
			inner join #concedii i on ca.Marca=i.Marca and ca.Data=i.Data
			left outer join personal p on p.Marca=i.Marca
		where CHARINDEX(ca.Tip_concediu,'5ABCDEN')=0
			and (i.fel<>'CA' or ca.Data_inceput<>i.Data_inceput)
			and (i.Data_inceput between ca.Data_inceput and ca.Data_sfarsit or i.Data_sfarsit between ca.Data_inceput and ca.Data_sfarsit
			or ca.Data_inceput between i.Data_inceput and i.Data_sfarsit)
		raiserror(@mesajeroare,16,1)
	end

--	validare suprapunere cu concedii de odihna
	if exists (select 1 from ConcOdih co 
			inner join #concedii i on co.Marca=i.Marca and co.Data=i.Data
		where CHARINDEX(co.Tip_concediu,'3569CPV')=0 
			and (i.fel<>'CO' or co.Data_inceput<>i.Data_inceput)
			and (i.Data_inceput between co.Data_inceput and co.Data_sfarsit or i.Data_sfarsit between co.Data_inceput and co.Data_sfarsit
				or co.Data_inceput between i.Data_inceput and i.Data_sfarsit)
			and not exists (select 1 from ConcOdih co1 where co1.Tip_concediu='5' 
				and (i.Data_inceput between co1.Data_inceput and co1.Data_sfarsit or i.Data_sfarsit between co1.Data_inceput and co1.Data_sfarsit
					or co1.Data_inceput between i.Data_inceput and i.Data_sfarsit)))
	begin	
		select @mesajeroare='Eroare operare '+rtrim(nume_tabela)+': Exista concediu de odihna in luna care se suprapune cu aceasta perioada (salariatul '+rtrim(p.nume)+' - '+rtrim(co.marca)+') !'
		from ConcOdih co 
			inner join #concedii i on co.Marca=i.Marca and co.Data=i.Data
			left outer join personal p on p.Marca=i.Marca
		where CHARINDEX(co.Tip_concediu,'3569CPV')=0 
			and (i.fel<>'CO' or co.Data_inceput<>i.Data_inceput)
			and (i.Data_inceput between co.Data_inceput and co.Data_sfarsit or i.Data_sfarsit between co.Data_inceput and co.Data_sfarsit
				or co.Data_inceput between i.Data_inceput and i.Data_sfarsit)
			and not exists (select 1 from ConcOdih co1 where co1.Tip_concediu='5' 
				and (i.Data_inceput between co1.Data_inceput and co1.Data_sfarsit or i.Data_sfarsit between co1.Data_inceput and co1.Data_sfarsit
					or co1.Data_inceput between i.Data_inceput and i.Data_sfarsit))
		raiserror(@mesajeroare,16,1)
	end

--	validare suprapunere cu concedii medicale
	if exists (select 1 from conmed cm 
			inner join #concedii i on cm.Marca=i.Marca and cm.Data=i.Data
		where (i.fel<>'CM' or cm.Data_inceput<>i.Data_inceput)
			and (i.Data_inceput between cm.Data_inceput and cm.Data_sfarsit or i.Data_sfarsit between cm.Data_inceput and cm.Data_sfarsit
				or cm.Data_inceput between i.Data_inceput and i.Data_sfarsit))
	begin
		select @mesajeroare='Eroare operare '+rtrim(nume_tabela)+': Exista concediu medical in luna care se suprapune cu aceasta perioada (salariatul '+rtrim(p.nume)+' - '+rtrim(cm.marca)+') !'
		from conmed cm 
			inner join #concedii i on cm.Marca=i.Marca and cm.Data=i.Data
			left outer join personal p on p.Marca=i.Marca
		where (i.fel<>'CM' or cm.Data_inceput<>i.Data_inceput)
			and (i.Data_inceput between cm.Data_inceput and cm.Data_sfarsit or i.Data_sfarsit between cm.Data_inceput and cm.Data_sfarsit
				or cm.Data_inceput between i.Data_inceput and i.Data_sfarsit)
		raiserror(@mesajeroare,16,1)
	end

--	validare suprapunere cu perioade de suspendare ale contractului de munca
	if exists (select 1 from dbo.fRevisalSuspendari ('01/01/1901', '12/31/2999', '') s 
			inner join #concedii i on s.Marca=i.Marca 
		where i.fel<>'CA' -- nu fac validarea suprapunerii pentru concedii/Alte intrucat aici pot si CFS-uri care se regasesc si la suspendari (similar ingrijire copil). Poate mai incolo daca trebuie.
			and (i.fel<>'CM' or i.tip_concediu<>'0-' or (i.tip_concediu='0-' and s.Temei_legal not in ('Art51Alin1LiteraA','Art51Alin1LiteraB','Art51Alin1LiteraC')))
			and (i.Data_inceput between s.Data_inceput and s.Data_final or i.Data_sfarsit between s.Data_inceput and s.Data_final
				or s.Data_inceput between i.Data_inceput and i.Data_sfarsit))
	begin
		select @mesajeroare='Eroare operare '+rtrim(nume_tabela)+': Exista o suspendare in luna care se suprapune cu aceasta perioada (salariatul '+rtrim(p.nume)+' - '+rtrim(s.marca)+') !'
		from dbo.fRevisalSuspendari ('01/01/1901', '12/31/2999', '') s 
			inner join #concedii i on s.Marca=i.Marca 
			left outer join personal p on p.Marca=i.Marca
		where (i.fel<>'CM' or i.tip_concediu<>'0-' or (i.tip_concediu='0-' and s.Temei_legal<>'Art51Alin1LiteraA'))
			and (i.Data_inceput between s.Data_inceput and s.Data_final or i.Data_sfarsit between s.Data_inceput and s.Data_final
				or s.Data_inceput between i.Data_inceput and i.Data_sfarsit)
		raiserror(@mesajeroare,16,1)
	end

--	validare suprapunere cu informatii pontaj
	if exists (select 1 from infopontaj ip 
			inner join #concedii i on ip.Marca=i.Marca and ip.Data=i.Data
		where (i.fel='CA' and (case when ip.Tip='7' then '2' when ip.Tip='8' then '1' else ip.Tip end)<>i.Tip_concediu 
					or i.fel='CM' and ip.Tip<>'1' or i.fel='CO' and ip.Tip<>'2')
			and (i.Data_inceput between ip.Data_inceput and ip.Data_sfarsit or i.Data_sfarsit between ip.Data_inceput and ip.Data_sfarsit
				or ip.Data_inceput between i.Data_inceput and i.Data_sfarsit))
	begin
		raiserror('Eroare operare (conalte.tr_ValidConalte): Exista date in informatii pontaj in luna care se suprapun cu aceasta perioada!',16,1)
	end

end try

begin catch
	DECLARE @mesaj varchar(max)
	set @mesaj=ERROR_MESSAGE()+ ' (validConcedii)'
	raiserror(@mesaj, 16,1)
end catch

