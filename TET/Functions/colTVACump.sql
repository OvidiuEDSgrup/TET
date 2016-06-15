--***
create function colTVACump (@TipTert int, @Teritoriu char(1), @CotaTVA int, @Exonerat int, @VanzCump char(1), @CtCoresp varchar(40), @TipNomencl char(1))
returns int
begin
 if @CotaTVA is null set @CotaTVA = 0
 if @Exonerat is null set @Exonerat = 0
 if @VanzCump is null set @VanzCump = ''
 if @CtCoresp is null set @CtCoresp = ''
 if @TipTert is null set @TipTert = 0
 if @Teritoriu is not null begin
  -- factura de la tert UE, marfa vine din afara UE
  if @TipTert = 1 and @Teritoriu <> 'U' set @TipTert = 2
  -- factura de la tert extern, marfa vine din UE
  if @TipTert = 2 and @teritoriu = 'U' set @TipTert = 1
 end
 if @TipNomencl is null set @TipNomencl = ''
 
 return 
 (case 
  when @TipTert <> 1 and not (@Exonerat > 0 and @VanzCump = 'C') then 
   (case 
    when @CotaTVA = 19 then 
     (case 
      when @Exonerat = 0 and exists (select 1 from ContRapTVA where HostID=host_id() and tip='C' and @CtCoresp like RTrim(Cont)+'%') then 1 
      when @Exonerat = 0 and (left(@CtCoresp, 3) = '371' or exists (select 1 from ContRapTVA where HostID=host_id() and tip='R' and @CtCoresp like RTrim(Cont)+'%')) then 2 
      else 3 
     end)
    when @CotaTVA = 9 then 
     (case 
      when @Exonerat = 0 and (left(@CtCoresp, 3) = '371' or exists (select 1 from ContRapTVA where HostID=host_id() and tip='R' and @CtCoresp like RTrim(Cont)+'%')) then 4 
      else 5 
     end)
    when @CotaTVA = 0 then 6 
    else 0 
   end)
  when @TipTert = 1 then
   (case 
    when left(@CtCoresp, 3) = '371' or exists (select 1 from ContRapTVA where HostID=host_id() and tip='R' and @CtCoresp like RTrim(Cont)+'%') then 
     (case 
      when @CotaTVA <> 0 then 
       (case when (1=1 or @Exonerat > 0) and @VanzCump = 'C' and @TipNomencl in ('', 'R', 'S') then 9 else 7 end)
      else 8 
     end) 
    else 
     (case 
      when @CotaTVA <> 0 then 
       (case when (1=1 or @Exonerat > 0) and @VanzCump = 'C' and @TipNomencl in ('', 'R', 'S') then 13 else 11 end)
      else 12 
     end) 
   end)
  when @TipTert <> 1 and @Exonerat > 0 and @VanzCump = 'C' then 15 
 else 0 end)
end
