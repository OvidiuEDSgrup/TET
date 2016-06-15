--***
/**	functie ce returneaza date pt. declaratia 205 */
Create function [dbo].[fDeclaratia205] (@DataJ datetime, @DataS datetime, @tipdecl int, @TipVenit char(2), 
	@TipImpozit char(1), @lmjos char(9), @lmsus char(9), @ContImpozit char(30), @ContFactura char(30))
returns @date205 table
	(Data datetime, CNP char(13), Nume char(200), Baza_impozit decimal(10), Impozit decimal(10), CampD205 varchar(max))
as  
Begin
	declare @Luna int, @An int, @LunaAlfa varchar(15), 
	@Sub char(9), @vcif varchar(13), @cif varchar(13), @den char(200), @TotalImpozit decimal(12)

	select @Sub=dbo.iauParA('GE','SUBPRO'), @vcif=dbo.iauParA('GE','CODFISC'), @den=dbo.iauParA('GE','NUME')
		
	Select @cif=ltrim(rtrim((case when left(upper(@vcif),2)='RO' then substring(@vcif,3,13)
		when left(upper(@vcif),1)='R' then substring(@vcif,2,13) else @vcif end)))
	select @luna=month(@DataS), @An=year(@DataS)

	if exists (select 1 from sysobjects where [type]='P' and [name]='fDeclaratia205SP')
		exec fDeclaratia205SP @DataJ, @DataS, @tipdecl, @TipVenit, @TipImpozit, @lmjos, @lmsus
	else 
	Begin
--		completez tabela temporara pt. impozit aferent tip venit=17 (impozit din vanzare desesuri)
--		primul select este pornit de la specificul Grupului RematInvest (au evidentiat impozitul direct pe receptie pe un alt cod cu minus)
--		(linia cu cod=IMPPF are in cantitate procentul de impozit si in campul pret de stoc are baza impozitului/100)
--		selectul de dupa union all se refera la cei care au evidentiat retinerea impozitului prin plata furnizor

		declare @impozit17 table
		(Data datetime, CNP char(13), Nume char(200), Baza_impozit decimal(10), Impozit decimal(10))
		insert into @impozit17
		select @DataS, left(rtrim(t.Cod_fiscal),13), max(t.Denumire), round(sum(p.Pret_de_stoc*100),0), 
		round(sum(ROUND(-p.Cantitate*p.Pret_de_stoc,2)),0)
		from pozdoc p
			left outer join terti t on p.Subunitate=t.Subunitate and p.Tert=t.Tert
		where @TipVenit='17' and p.Subunitate=@Sub and Data between @DataJ and @DataS and p.Tip='RM'
			and (charindex(',',@ContImpozit)=0 and p.Cont_de_stoc=@ContImpozit or charindex(',',@ContImpozit)<>0 and charindex(rtrim(p.Cont_de_stoc),@ContImpozit)<>0)
			and (charindex(',',@ContFactura)=0 and p.Cont_factura=@ContFactura or charindex(',',@ContFactura)<>0 and charindex(rtrim(p.Cont_factura),@ContFactura)<>0)
		Group by t.Cod_fiscal
		union all 
		select @DataS, left(rtrim(t.Cod_fiscal),13), max(t.Denumire), sum(f.Valoare), sum(p.Suma)
		from pozplin p
			left outer join terti t on p.Subunitate=t.Subunitate and p.Tert=t.Tert
			left outer join facturi f on f.Subunitate=p.Subunitate and f.Factura=p.Factura and f.Tert=p.Tert and f.Tip=0x54
		where @TipVenit='17' and p.Subunitate=@Sub and p.Data between @DataJ and @DataS and p.Plata_incasare='PF'
			and p.Cont=@ContImpozit and p.Cont_corespondent=@ContFactura
		Group by t.Cod_fiscal

--		inserez total general ca header fisier (prima linie din fisierul exportat)
		if @TipVenit in ('01','06')
			select @TotalImpozit=sum(n.Impozit) from net n
				left outer join istPers i on i.Data=n.Data and i.Marca=n.Marca
			where n.Data between @DataJ and @DataS and n.Data=dbo.EOM(n.Data)
				and (@TipVenit='01' and i.Tip_colab='DAC' or @TipVenit='06' and i.Tip_colab='CCC')
				and (@TipImpozit='1' and i.Tip_impozitare='8' or @TipImpozit='2' and i.Tip_impozitare<>'8')
		if @TipVenit='17'
			select @TotalImpozit=sum(Impozit) from @impozit17

		set @TotalImpozit=isnull(@TotalImpozit,0)

		insert into @date205 
		select @DataS, @cif, @den, 0, @TotalImpozit, 
			convert(char(4),YEAR(@DataS))+','+(case when @tipdecl=0 then '1' else '2' end)
			+@TipImpozit+','+rtrim(@cif)+','+RTRIM(@TipVenit)+','+rtrim(convert(char(12),CONVERT(decimal(12),@TotalImpozit)))

--		inserez salariatii care trebuie sa apara in declaratie
		insert into @date205
		select @DataS, p.Cod_numeric_personal, max(p.Nume) as Nume, sum(n.Venit_baza), sum(n.Impozit),
			rtrim(p.Cod_numeric_personal)+','+rtrim(convert(char(10),sum(n.Venit_baza)))+','+rtrim(convert(char(10),sum(n.Impozit)))+',,'
		from net n
			left outer join personal p on p.Marca=n.Marca
			left outer join istPers i on i.Data=n.Data and i.Marca=n.Marca
		where n.Data between @DataJ and @DataS and n.Data=dbo.EOM(n.Data)
			and (@TipVenit='01' and i.Tip_colab='DAC' or @TipVenit='06' and i.Tip_colab='CCC')
			and (@TipImpozit='1' and i.Tip_impozitare='8' or @TipImpozit='2' and i.Tip_impozitare<>'8')
		group by p.Cod_numeric_personal

--		inserez persoanele care au realizat venituri din vanzare deseuri (din CG)
		insert into @date205
		select Data, CNP, max(Nume), sum(Baza_impozit), sum(impozit), 
		rtrim(CNP)+','+rtrim(convert(char(10),sum(Baza_impozit)))+','+rtrim(convert(char(10),sum(Impozit)))+',,'
		from @impozit17
		Group by Data, CNP
	End

	return
End

/*
	select * from fDeclaratia205 ('01/01/2011', '12/31/2011', 0, '06', '2', Null, Null, '446.5','462.2')
*/
