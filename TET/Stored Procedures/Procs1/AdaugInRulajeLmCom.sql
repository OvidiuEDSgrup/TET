--***
create procedure AdaugInRulajeLmCom @cSub char(9), @cCont char(13), @cValuta char(3), @dData datetime, @LM char(9), @Comanda char(40), @RulDeb float, @RulCred float
as

while isnull(@cCont, '')<>''
begin
	if not exists (select 1 from rulaje_lmcom where subunitate=@cSub and cont=@cCont and valuta=@cValuta and data=@dData and loc_de_munca=@LM and comanda=@Comanda)
		insert Rulaje_lmcom
		(Subunitate, Cont, Valuta, Data, Loc_de_munca, Comanda, Rulaj_debit, Rulaj_credit)
		values
		(@cSub, @cCont, @cValuta, @dData, @LM, @Comanda, @RulDeb, @RulCred)
	else
		update rulaje_lmcom
		set Rulaj_debit=Rulaj_debit + @RulDeb,
			Rulaj_credit=Rulaj_credit + @RulCred
		where subunitate=@cSub and cont=@cCont and valuta=@cValuta and data=@dData and loc_de_munca=@LM and comanda=@Comanda

	set @cCont=isnull((select max(cont_parinte) from conturi where subunitate=@cSub and cont=@cCont), '')
end
