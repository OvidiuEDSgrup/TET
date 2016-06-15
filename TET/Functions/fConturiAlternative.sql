create function fConturiAlternative (@cont varchar(40), @limba varchar(100))
returns @conturiCorespondente table(
		Subunitate varchar(9),
		Cont varchar(40),
		ContOriginal varchar(40),
		Denumire_cont varchar(300),
		Tip_cont varchar(1),
		Cont_parinte varchar(40),
		Are_analitice smallint,
		Apare_in_balanta_sintetica smallint,
		Sold_debit float,
		Sold_credit float,
		Nivel smallint,
		Articol_de_calculatie varchar(20),
		Logic smallint
	)
as
begin
	declare @filtruCont bit
	select @filtruCont=(case when @cont is null then 0 else 1 end)
	
	if @limba is null
	begin
		insert into @conturiCorespondente (Subunitate, Cont, ContOriginal, Denumire_cont, Tip_cont, Cont_parinte,
				Are_analitice, Apare_in_balanta_sintetica, Sold_debit, Sold_credit, Nivel,
				Articol_de_calculatie, Logic)
		select Subunitate, Cont, Cont, Denumire_cont, Tip_cont, Cont_parinte,
				Are_analitice, Apare_in_balanta_sintetica, Sold_debit, Sold_credit, Nivel,
				Articol_de_calculatie, Logic from conturi

	end
	else
	begin
		declare @listaConturiCorespondente table (Cont_strain varchar(40), dens varchar(1000), contcg varchar(40), cont_parinte varchar(40), Are_analitice smallint)
	if @limba=''
		insert into @listaConturiCorespondente (Cont_strain, dens, contcg, cont_parinte, Are_analitice)
			select p.valoare, max(isnull(p2.descriere,'<Fara denumire>')), p.cod, '', 1
			from proprietati p
					left join conturialternative p2 on p2.cont=p.valoare --> denumiri conturi
			where p.tip='CONT' and p.cod_proprietate='CONTCOR'
		group by p.valoare, p.cod
	else
		insert into @listaConturiCorespondente (Cont_strain, dens, contcg, cont_parinte, Are_analitice)
			select p.valoare, max(isnull(p2.valoare,'<Fara denumire>')), p.cod, '', 1
			from proprietati p
					left join proprietati p2 on p2.tip='CONTCOR' and p2.cod_proprietate='DENCONTCOR_'+@limba and p.valoare=p2.cod --> denumiri conturi
			where p.tip='CONT' and p.cod_proprietate='CONTCOR'
		group by p.valoare, p.cod

		insert into @conturiCorespondente (Subunitate, Cont, ContOriginal, Denumire_cont, Tip_cont, Cont_parinte,
				Are_analitice, Apare_in_balanta_sintetica, Sold_debit, Sold_credit, Nivel,
				Articol_de_calculatie, Logic)
		select max(c.Subunitate) Subunitate, max(isnull(cc.Cont_strain,'<nedefinit>')), c.Cont,
				max(isnull(cc.DenS,'<Fara denumire>')), max(c.Tip_cont), max(cc.cont_parinte) Cont_parinte,
				max(isnull(cc.Are_analitice,0)), max(case when isnull(c.Apare_in_balanta_sintetica,1)=1 then 1 else 0 end), max(isnull(c.Sold_debit,0)), max(isnull(c.Sold_credit,0)), max(c.Nivel),
				max(c.Articol_de_calculatie), max(case when c.Logic=1 then 1 else 0 end)
		from conturi c left join @listaConturiCorespondente cc on rtrim(cc.contcg)=rtrim(c.cont)
		where (@filtruCont=0 or c.cont like @cont) and c.are_analitice=0
		group by c.cont,isnull(cc.Cont_strain,'<Fara contcor>'),cc.cont_parinte
		
		--> varianta anterioara (cu contcor)
		/*
		select  c.Subunitate, isnull(cc.Cont_strain,'<Fara contcor>'), c.Cont, isnull(cc.DenS,'<Fara contcor>'), c.Tip_cont, '' Cont_parinte,
				0, isnull(c.Apare_in_balanta_sintetica,1), isnull(c.Sold_debit,0), isnull(c.Sold_credit,0), c.Nivel,
				c.Articol_de_calculatie, c.Logic
			from conturi c left join contcor cc on rtrim(cc.contcg)=rtrim(c.cont)
		where (@filtruCont=0 or c.cont like @cont) and c.are_analitice=0--*/
	end
	return
end
