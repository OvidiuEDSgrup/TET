--***
create procedure AdaugInRulaje 
	@cSub char(9), @cCont varchar(40), @cValuta char(3), @dData datetime, @RulDeb float, @RulCred float, @cLm char(9), @Indbug varchar(20)=''
as

while isnull(@cCont, '')<>''
begin
	if not exists (select 1 from rulaje where subunitate=@cSub and cont=@cCont and Loc_de_munca=@cLm and Indbug=@Indbug and valuta=@cValuta and data=@dData)
		insert Rulaje
		(Subunitate, Cont, Loc_de_munca, Indbug, Valuta, Data, Rulaj_debit, Rulaj_credit)
		values
		(@cSub, @cCont, @cLm, @Indbug, @cValuta, @dData, @RulDeb, @RulCred)
		
	else
		update rulaje
		set Rulaj_debit=Rulaj_debit + @RulDeb,
			Rulaj_credit=Rulaj_credit + @RulCred
		where subunitate=@cSub and cont=@cCont and Loc_de_munca=@cLm and Indbug=@Indbug and valuta=@cValuta and data=@dData
	set @cCont=isnull((select max(cont_parinte) from conturi where subunitate=@cSub and cont=@cCont), '')
end
