--***
create procedure [dbo].[scriuFisaMF] @sub varchar(9), @nrinv varchar(13), @categmf int, @datal datetime, @felop char(1), 
	@lm varchar(9), @gestiune varchar(9), @comanda varchar(40), 
	@valinv float, @valam float, @valamcls8 float, @valamneded float, @amlun float, @amluncls8 float, @amlunneded float, 
	@durata int, @obinv int, @contmf varchar(40), @nrluni int, @rezreev float, @contam varchar(40), @contcham varchar(40)
as
begin try
	declare @mesaj varchar(1000)

	delete from fisamf where Subunitate=@sub and Numar_de_inventar=@nrinv and Data_lunii_operatiei=@datal and Felul_operatiei=@felop
	INSERT into fisamf 
		(Subunitate, Numar_de_inventar, Categoria, Data_lunii_operatiei, Felul_operatiei, 
		Loc_de_munca, Gestiune, Comanda, Valoare_de_inventar, 
		Valoare_amortizata, Valoare_amortizata_cont_8045, Valoare_amortizata_cont_6871, 
		Amortizare_lunara, Amortizare_lunara_cont_8045, Amortizare_lunara_cont_6871, 
		Durata, Obiect_de_inventar, Cont_mijloc_fix, Numar_de_luni_pana_la_am_int, Cantitate, Cont_amortizare, Cont_cheltuieli)
	select @sub, @nrinv, @categmf, @datal, @felop, @lm, @gestiune, @comanda, 
		@valinv, @valam, @valamcls8, @valamneded, @amlun, @amluncls8, @amlunneded, 
		@durata, @obinv, @contmf, @nrluni, @rezreev, @contam, @contcham
end try

begin catch
	--ROLLBACK TRAN
	set @mesaj = ERROR_MESSAGE()+ '(scriuFisaMF)'
	raiserror(@mesaj, 11, 1)
end catch
