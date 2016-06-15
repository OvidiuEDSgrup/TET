-- citeste discountul minim, maxim si pasul pentru numeric stepper -> de tratat in proceduri specifice daca se doreste setarea discountului la nivel de agent...
CREATE procedure wmIaDiscountAgent @sesiune varchar(50), @discountMinim decimal(12,2) output, @discountMaxim decimal(12,2) output, @pasDiscount decimal(12,2) output
as
set transaction isolation level READ UNCOMMITTED

if exists(select * from sysobjects where name='wmIaDiscountAgentSP' and type='P')
begin
	exec wmIaDiscountAgentSP @sesiune=@sesiune, @discountMinim=@discountMinim output, @discountMaxim=@discountMaxim output, @pasDiscount=@pasDiscount output
	return 0
end

select @discountMinim=0, @discountMaxim=0, @pasDiscount=0

select	@discountMinim = (case when parametru='DISCMIN' then Val_numerica else @discountMinim end), 
		@discountMaxim = (case when parametru='DISCMAX' then Val_numerica else @discountMaxim end), 
		@pasDiscount = (case when parametru='DISCPAS' then Val_numerica else @pasDiscount end)
from par
where Tip_parametru='AM' and Parametru in ('DISCMAX', 'DISCMIN', 'DISCPAS')


