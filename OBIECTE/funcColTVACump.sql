drop function [dbo].[funcColTVACump] 
go
create function [dbo].[funcColTVACump] (@Coloana int, @CotaTVA float, @Exonerat int, @VanzCump char(1), 
@CtCoresp char(13), @ListaCtNeimpoz char(200), @TipTert int, @Teritoriu char(1), @TipNom char(1), 
@Tert char(13), @Factura char(20), @TipDoc char(2), @NrDoc char(10), @DataDoc datetime, @NrPoz int, 
@ContPI char(13), @TipPI char(2), @Cod char(20)) 
returns int
as begin
-- tratare cazuri particulare
declare @Comunitar int
set @Comunitar = (case when @Teritoriu is null and @TipTert=1 or @Teritoriu='U' then 1 else 0 end)
-- in coloana 15 (Oblig. la plata taxei art. 160)
--if @Tiptert = 1 and @CotaTva =0 and @coloana in (11, 12, 13, 14,21 ,23) return 13

--if @Comunitar = 1 and @TipDoc in ('RP','RS') and @Coloana in (11, 12, 13, 14, 21, 23)return 15

--if @Comunitar = 1 and @TipDoc in ('SF') and @Coloana in (11, 12, 13, 14, 21, 23) return 11

--if @TipDoc = 'SF' and @CtCoresp like '408%' and @Coloana in (11,12,13,14,21,23) 
--	and exists (select 1 from pozadoc pa inner join pozdoc p on pa.tert = p.tert and pa.factura_stinga = p.factura 
--				where pa.tip = @TipDoc and pa.numar_document = @NrDoc and pa.data = @DataDoc and pa.numar_pozitie = @NrPoz 
--				and p.tip != 'RM') 
--	return 15 

--if @TipTert=1 and @TipDoc='RM' and exists (select 1 from doc where subunitate='1' and tip=@TipDoc and numar=@NrDoc and data=@DataDoc and cod_gestiune in ('ADEZIVARE', 'ZINCARE','FOSFATARE','AB ZINC')) return 15

if @Coloana in (15,21) and left(@CtCoresp, 3) in ('609') --and @TipNom = 'R' and @TipDoc in ('RS') 
	return 11

return @Coloana -- ramane coloana determinata initial daca nu este caz particular
end