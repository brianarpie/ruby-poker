class HandEvaluator

  @@div4 = [0,0,0,0, 1,1,1,1, 2,2,2,2, 3,3,3,3, 4,4,4,4, 5,5,5,5, 6,6,6,6, 7,7,7,7,
          8,8,8,8, 9,9,9,9, 10,10,10,10, 11,11,11,11, 12,12,12,12, 13,13,13,13]
  @@mod4 = [0,1,2,3, 0,1,2,3, 0,1,2,3, 0,1,2,3, 0,1,2,3, 0,1,2,3, 0,1,2,3, 0,1,2,3,
          0,1,2,3, 0,1,2,3, 0,1,2,3, 0,1,2,3, 0,1,2,3, 0,1,2,3]

  @@mult = Array.new(6) { Array.new(14) }
  @@mul = [0, 1, 15, 225, 3375, 50625]
  for i in 0..5
    for j in 0..13
      @@mult[i][j] = @@mul[i] * j
    end
  end

  def define_hand(cards)
    max = 0
    cards.permutation(5).to_a.each { |c|
      c.sort!{|x, y| y <=> x}
      temp = get_value(c[0], c[1], c[2], c[3], c[4])
      if temp > max then max = temp end
    }
    max
  end

  def get_value x1, x2, x3, x4, x5
    z0, z1, z2, z3, z4 = @@div4[x1], @@div4[x2], @@div4[x3], @@div4[x4], @@div4[x5]
    c0, c1, c2, c3, c4 = @@mod4[x1], @@mod4[x2], @@mod4[x3], @@mod4[x4], @@mod4[x5]
    flush = c0 == c1 && c1 == c2 && c2 == c3 && c3 == c4

    diff = 0
    if z0 != z1 then diff += 1 end
    if z1 != z2 then diff += 1 end
    if z2 != z3 then diff += 1 end
    if z3 != z4 then diff += 1 end

    straight = false

    if diff == 4
      if (z4 == z0 - 4) && (z1 == z0 - 1) && (z2 == z1 - 1) && (z3 == z2 - 1)
        straight = true
      elsif z0 == 12 && z1 == 3
        straight = true # A 2 3 4 5
      end
    end

    # Royal Flush / Straight Flush
    if straight && flush
      if z0 == 12 && z1 == 3 then return 10000000 + z1 end# 5-high straight flush
      return 10000000 + z0 # only highest card matters
    end

    # Four of a Kind
    if diff == 1 && z1 == z2 && z2 == z3
      if z0 != z1
        return 8000000 + @@mult[5][z1] + z0
      else
        return 8000000 + @@mult[5][z1] + z4
      end
    end

    # Full House
    if diff == 1
      if z0 == z2 # aaabb
        return 7000000 + @@mult[5][z2] + z4
      else
        return 7000000 + @@mult[5][z2] + z0
      end
    end

    # Flush
    if flush
      return 6000000 + @@mult[5][z0] + @@mult[4][z1] + @@mult[3][z2] + @@mult[2][z3] + @@mult[1][z4]
    end

    # Straight
    if straight
      if z0 == 12 && z1 == 3 then return 5000000 + z1 end # 5-high straight
      return 5000000 + z0 # only highest card matters
    end

    # Three of a Kind
    if diff == 2
      if z2 == z0 then return 4000000 + @@mult[5][z2] + @@mult[2][z3] + z4 end
      if z2 == z4 then return 4000000 + @@mult[5][z2] + @@mult[2][z0] + z1 end
      if z1 == z3 then return 4000000 + @@mult[5][z2] + @@mult[2][z0] + z4 end
    end

    # Two Pairs
    if diff == 2
      if z0 == z1
        if z2 == z3 then return 3000000 + @@mult[5][z0] + @@mult[3][z2] + @@mult[2][z4] end
        if z3 == z4 then return 3000000 + @@mult[5][z0] + @@mult[3][z3] + @@mult[2][z2] end
      end
      if z1 == z2 && z3 == z4 then return 3000000 + @@mult[5][z1] + @@mult[3][z3] + @@mult[2][z0] end
    end

    # One Pair
    if diff == 3
      # aabcd, baacd, bcaad, bcdaa
      if z0 == z1 then return 2000000 + @@mult[5][z0] + @@mult[3][z2] + @@mult[2][z3] + @@mult[1][z4] end
      if z1 == z2 then return 2000000 + @@mult[5][z1] + @@mult[3][z0] + @@mult[2][z3] + @@mult[1][z4] end
      if z2 == z3 then return 2000000 + @@mult[5][z2] + @@mult[3][z0] + @@mult[2][z1] + @@mult[1][z4] end
      if z3 == z4 then return 2000000 + @@mult[5][z3] + @@mult[3][z0] + @@mult[2][z1] + @@mult[1][z2] end
    end

    # High Card
    return @@mult[5][z0] + @@mult[4][z1] + @@mult[3][z2] + @@mult[2][z3] + @@mult[1][z4];  # all cards matter

  end
end
