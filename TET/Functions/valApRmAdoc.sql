--***
create function  valApRmAdoc 
(
 @Sb char(9), @TipAdoc char(2), @Tert char(13), @Factura char(20), 
 @CotaTVA int, @Bunuri int, @CapitalRevanzare char(1)
)
returns float
begin
declare @val float

select @val=sum(round(convert(decimal(15,3), p.cantitate*(case when p.tip='RM' then p.pret_valuta*(case when p.valuta<>'' then p.curs else 1 end)*(1.00+p.discount/100.00) else p.pret_vanzare end)), 2))
from pozdoc p
left outer join nomencl n on p.cod = n.cod
where p.subunitate = @Sb and (@TipAdoc = 'IF' and p.tip = 'AP' or @TipAdoc = 'SF' and p.tip = 'RM') 
and p.tert = @Tert and p.factura = @Factura
and (@CotaTVA is null or p.cota_TVA = @CotaTVA)
and (@Bunuri = 0 or @Bunuri = 1 and isnull(n.tip, '') not in ('R', 'S', '') or @Bunuri = 2 and isnull(n.tip, '') in ('R', 'S', ''))
and (@CapitalRevanzare = '' or left(p.tip, 1) <> 'R' or exists (select 1 from ContRapTVA c where c.HostID=host_id() and c.tip=@CapitalRevanzare and p.cont_de_stoc like RTrim(c.Cont)+'%'))

return isnull(@val,0)
end
