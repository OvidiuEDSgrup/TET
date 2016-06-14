select 1.04682*4.3434
select convert(decimal(18, 5), dbo.rot_pret(        1.04682*4.3434,0.01))
select convert(decimal(18, 5), 4.546757988) / convert(decimal(18, 5), 0.01)
select convert(decimal(18, 5),4.546757988+0.01 -convert(decimal(18, 5), 4.546757988) % convert(decimal(18, 5), 0.01))
