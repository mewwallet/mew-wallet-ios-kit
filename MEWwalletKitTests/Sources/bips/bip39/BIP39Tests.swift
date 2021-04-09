//
//  BIP39Tests.swift
//  MEWwalletKitTests
//
//  Created by Mikhail Nikanorov on 4/15/19.
//  Copyright © 2019 MyEtherWallet Inc. All rights reserved.
//

// swiftlint:disable line_length

import Foundation
import Quick
import Nimble
@testable import MEWwalletKit

class BIP39Tests: QuickSpec {
  class TestVector {
    let language: BIP39Wordlist
    let entropy: Data
    let mnemonic: [String]
    let seed: Data
    let password: String?
    
    init(language: BIP39Wordlist, _ entropy: String, _ mnemonic: String, _ seed: String, _ password: String? = nil) {
      self.language = language
      self.entropy = Data(hex: entropy)
      let separators = CharacterSet(charactersIn: " 　") // space + ideographic space
      self.mnemonic = mnemonic.components(separatedBy: separators)
      self.seed = Data(hex: seed)
      self.password = password
    }
  }
  
  lazy var testVectors: [TestVector] = {
    let customLanguage = BIP39Wordlist.custom(words: ["aband0n", "ab1l1ty", "abl3", "ab0ut", "ab0v3", "ab53nt", "ab50rb", "ab5tract", "ab5urd", "abu53", "acc355", "acc1d3nt", "acc0unt", "accu53", "ach13v3", "ac1d", "ac0u5t1c", "acqu1r3", "acr055", "act", "act10n", "act0r", "actr355", "actual", "adapt", "add", "add1ct", "addr355", "adju5t", "adm1t", "adult", "advanc3", "adv1c3", "a3r0b1c", "affa1r", "aff0rd", "afra1d", "aga1n", "ag3", "ag3nt", "agr33", "ah3ad", "a1m", "a1r", "a1rp0rt", "a15l3", "alarm", "album", "alc0h0l", "al3rt", "al13n", "all", "all3y", "all0w", "alm05t", "al0n3", "alpha", "alr3ady", "al50", "alt3r", "alway5", "amat3ur", "amaz1ng", "am0ng", "am0unt", "amu53d", "analy5t", "anch0r", "anc13nt", "ang3r", "angl3", "angry", "an1mal", "ankl3", "ann0unc3", "annual", "an0th3r", "an5w3r", "ant3nna", "ant1qu3", "anx13ty", "any", "apart", "ap0l0gy", "app3ar", "appl3", "appr0v3", "apr1l", "arch", "arct1c", "ar3a", "ar3na", "argu3", "arm", "arm3d", "arm0r", "army", "ar0und", "arrang3", "arr35t", "arr1v3", "arr0w", "art", "art3fact", "art15t", "artw0rk", "a5k", "a5p3ct", "a55ault", "a553t", "a5515t", "a55um3", "a5thma", "athl3t3", "at0m", "attack", "att3nd", "att1tud3", "attract", "auct10n", "aud1t", "augu5t", "aunt", "auth0r", "aut0", "autumn", "av3rag3", "av0cad0", "av01d", "awak3", "awar3", "away", "aw350m3", "awful", "awkward", "ax15", "baby", "bach3l0r", "bac0n", "badg3", "bag", "balanc3", "balc0ny", "ball", "bamb00", "banana", "bann3r", "bar", "bar3ly", "barga1n", "barr3l", "ba53", "ba51c", "ba5k3t", "battl3", "b3ach", "b3an", "b3auty", "b3cau53", "b3c0m3", "b33f", "b3f0r3", "b3g1n", "b3hav3", "b3h1nd", "b3l13v3", "b3l0w", "b3lt", "b3nch", "b3n3f1t", "b35t", "b3tray", "b3tt3r", "b3tw33n", "b3y0nd", "b1cycl3", "b1d", "b1k3", "b1nd", "b10l0gy", "b1rd", "b1rth", "b1tt3r", "black", "blad3", "blam3", "blank3t", "bla5t", "bl3ak", "bl355", "bl1nd", "bl00d", "bl0550m", "bl0u53", "blu3", "blur", "blu5h", "b0ard", "b0at", "b0dy", "b01l", "b0mb", "b0n3", "b0nu5", "b00k", "b005t", "b0rd3r", "b0r1ng", "b0rr0w", "b055", "b0tt0m", "b0unc3", "b0x", "b0y", "brack3t", "bra1n", "brand", "bra55", "brav3", "br3ad", "br33z3", "br1ck", "br1dg3", "br13f", "br1ght", "br1ng", "br15k", "br0cc0l1", "br0k3n", "br0nz3", "br00m", "br0th3r", "br0wn", "bru5h", "bubbl3", "buddy", "budg3t", "buffal0", "bu1ld", "bulb", "bulk", "bull3t", "bundl3", "bunk3r", "burd3n", "burg3r", "bur5t", "bu5", "bu51n355", "bu5y", "butt3r", "buy3r", "buzz", "cabbag3", "cab1n", "cabl3", "cactu5", "cag3", "cak3", "call", "calm", "cam3ra", "camp", "can", "canal", "canc3l", "candy", "cann0n", "can03", "canva5", "cany0n", "capabl3", "cap1tal", "capta1n", "car", "carb0n", "card", "carg0", "carp3t", "carry", "cart", "ca53", "ca5h", "ca51n0", "ca5tl3", "ca5ual", "cat", "catal0g", "catch", "cat3g0ry", "cattl3", "caught", "cau53", "caut10n", "cav3", "c31l1ng", "c3l3ry", "c3m3nt", "c3n5u5", "c3ntury", "c3r3al", "c3rta1n", "cha1r", "chalk", "champ10n", "chang3", "cha05", "chapt3r", "charg3", "cha53", "chat", "ch3ap", "ch3ck", "ch3353", "ch3f", "ch3rry", "ch35t", "ch1ck3n", "ch13f", "ch1ld", "ch1mn3y", "ch01c3", "ch0053", "chr0n1c", "chuckl3", "chunk", "churn", "c1gar", "c1nnam0n", "c1rcl3", "c1t1z3n", "c1ty", "c1v1l", "cla1m", "clap", "clar1fy", "claw", "clay", "cl3an", "cl3rk", "cl3v3r", "cl1ck", "cl13nt", "cl1ff", "cl1mb", "cl1n1c", "cl1p", "cl0ck", "cl0g", "cl053", "cl0th", "cl0ud", "cl0wn", "club", "clump", "clu5t3r", "clutch", "c0ach", "c0a5t", "c0c0nut", "c0d3", "c0ff33", "c01l", "c01n", "c0ll3ct", "c0l0r", "c0lumn", "c0mb1n3", "c0m3", "c0mf0rt", "c0m1c", "c0mm0n", "c0mpany", "c0nc3rt", "c0nduct", "c0nf1rm", "c0ngr355", "c0nn3ct", "c0n51d3r", "c0ntr0l", "c0nv1nc3", "c00k", "c00l", "c0pp3r", "c0py", "c0ral", "c0r3", "c0rn", "c0rr3ct", "c05t", "c0tt0n", "c0uch", "c0untry", "c0upl3", "c0ur53", "c0u51n", "c0v3r", "c0y0t3", "crack", "cradl3", "craft", "cram", "cran3", "cra5h", "crat3r", "crawl", "crazy", "cr3am", "cr3d1t", "cr33k", "cr3w", "cr1ck3t", "cr1m3", "cr15p", "cr1t1c", "cr0p", "cr055", "cr0uch", "cr0wd", "cruc1al", "cru3l", "cru153", "crumbl3", "crunch", "cru5h", "cry", "cry5tal", "cub3", "cultur3", "cup", "cupb0ard", "cur10u5", "curr3nt", "curta1n", "curv3", "cu5h10n", "cu5t0m", "cut3", "cycl3", "dad", "damag3", "damp", "danc3", "dang3r", "dar1ng", "da5h", "daught3r", "dawn", "day", "d3al", "d3bat3", "d3br15", "d3cad3", "d3c3mb3r", "d3c1d3", "d3cl1n3", "d3c0rat3", "d3cr3a53", "d33r", "d3f3n53", "d3f1n3", "d3fy", "d3gr33", "d3lay", "d3l1v3r", "d3mand", "d3m153", "d3n1al", "d3nt15t", "d3ny", "d3part", "d3p3nd", "d3p051t", "d3pth", "d3puty", "d3r1v3", "d35cr1b3", "d353rt", "d351gn", "d35k", "d35pa1r", "d35tr0y", "d3ta1l", "d3t3ct", "d3v3l0p", "d3v1c3", "d3v0t3", "d1agram", "d1al", "d1am0nd", "d1ary", "d1c3", "d1353l", "d13t", "d1ff3r", "d1g1tal", "d1gn1ty", "d1l3mma", "d1nn3r", "d1n05aur", "d1r3ct", "d1rt", "d15agr33", "d15c0v3r", "d153a53", "d15h", "d15m155", "d150rd3r", "d15play", "d15tanc3", "d1v3rt", "d1v1d3", "d1v0rc3", "d1zzy", "d0ct0r", "d0cum3nt", "d0g", "d0ll", "d0lph1n", "d0ma1n", "d0nat3", "d0nk3y", "d0n0r", "d00r", "d053", "d0ubl3", "d0v3", "draft", "drag0n", "drama", "dra5t1c", "draw", "dr3am", "dr355", "dr1ft", "dr1ll", "dr1nk", "dr1p", "dr1v3", "dr0p", "drum", "dry", "duck", "dumb", "dun3", "dur1ng", "du5t", "dutch", "duty", "dwarf", "dynam1c", "3ag3r", "3agl3", "3arly", "3arn", "3arth", "3a51ly", "3a5t", "3a5y", "3ch0", "3c0l0gy", "3c0n0my", "3dg3", "3d1t", "3ducat3", "3ff0rt", "3gg", "31ght", "31th3r", "3lb0w", "3ld3r", "3l3ctr1c", "3l3gant", "3l3m3nt", "3l3phant", "3l3vat0r", "3l1t3", "3l53", "3mbark", "3mb0dy", "3mbrac3", "3m3rg3", "3m0t10n", "3mpl0y", "3mp0w3r", "3mpty", "3nabl3", "3nact", "3nd", "3ndl355", "3nd0r53", "3n3my", "3n3rgy", "3nf0rc3", "3ngag3", "3ng1n3", "3nhanc3", "3nj0y", "3nl15t", "3n0ugh", "3nr1ch", "3nr0ll", "3n5ur3", "3nt3r", "3nt1r3", "3ntry", "3nv3l0p3", "3p150d3", "3qual", "3qu1p", "3ra", "3ra53", "3r0d3", "3r0510n", "3rr0r", "3rupt", "35cap3", "355ay", "3553nc3", "35tat3", "3t3rnal", "3th1c5", "3v1d3nc3", "3v1l", "3v0k3", "3v0lv3", "3xact", "3xampl3", "3xc355", "3xchang3", "3xc1t3", "3xclud3", "3xcu53", "3x3cut3", "3x3rc153", "3xhau5t", "3xh1b1t", "3x1l3", "3x15t", "3x1t", "3x0t1c", "3xpand", "3xp3ct", "3xp1r3", "3xpla1n", "3xp053", "3xpr355", "3xt3nd", "3xtra", "3y3", "3y3br0w", "fabr1c", "fac3", "faculty", "fad3", "fa1nt", "fa1th", "fall", "fal53", "fam3", "fam1ly", "fam0u5", "fan", "fancy", "fanta5y", "farm", "fa5h10n", "fat", "fatal", "fath3r", "fat1gu3", "fault", "fav0r1t3", "f3atur3", "f3bruary", "f3d3ral", "f33", "f33d", "f33l", "f3mal3", "f3nc3", "f35t1val", "f3tch", "f3v3r", "f3w", "f1b3r", "f1ct10n", "f13ld", "f1gur3", "f1l3", "f1lm", "f1lt3r", "f1nal", "f1nd", "f1n3", "f1ng3r", "f1n15h", "f1r3", "f1rm", "f1r5t", "f15cal", "f15h", "f1t", "f1tn355", "f1x", "flag", "flam3", "fla5h", "flat", "flav0r", "fl33", "fl1ght", "fl1p", "fl0at", "fl0ck", "fl00r", "fl0w3r", "flu1d", "flu5h", "fly", "f0am", "f0cu5", "f0g", "f01l", "f0ld", "f0ll0w", "f00d", "f00t", "f0rc3", "f0r35t", "f0rg3t", "f0rk", "f0rtun3", "f0rum", "f0rward", "f0551l", "f05t3r", "f0und", "f0x", "frag1l3", "fram3", "fr3qu3nt", "fr35h", "fr13nd", "fr1ng3", "fr0g", "fr0nt", "fr05t", "fr0wn", "fr0z3n", "fru1t", "fu3l", "fun", "funny", "furnac3", "fury", "futur3", "gadg3t", "ga1n", "galaxy", "gall3ry", "gam3", "gap", "garag3", "garbag3", "gard3n", "garl1c", "garm3nt", "ga5", "ga5p", "gat3", "gath3r", "gaug3", "gaz3", "g3n3ral", "g3n1u5", "g3nr3", "g3ntl3", "g3nu1n3", "g35tur3", "gh05t", "g1ant", "g1ft", "g1ggl3", "g1ng3r", "g1raff3", "g1rl", "g1v3", "glad", "glanc3", "glar3", "gla55", "gl1d3", "gl1mp53", "gl0b3", "gl00m", "gl0ry", "gl0v3", "gl0w", "glu3", "g0at", "g0dd355", "g0ld", "g00d", "g0053", "g0r1lla", "g05p3l", "g0551p", "g0v3rn", "g0wn", "grab", "grac3", "gra1n", "grant", "grap3", "gra55", "grav1ty", "gr3at", "gr33n", "gr1d", "gr13f", "gr1t", "gr0c3ry", "gr0up", "gr0w", "grunt", "guard", "gu355", "gu1d3", "gu1lt", "gu1tar", "gun", "gym", "hab1t", "ha1r", "half", "hamm3r", "ham5t3r", "hand", "happy", "harb0r", "hard", "har5h", "harv35t", "hat", "hav3", "hawk", "hazard", "h3ad", "h3alth", "h3art", "h3avy", "h3dg3h0g", "h31ght", "h3ll0", "h3lm3t", "h3lp", "h3n", "h3r0", "h1dd3n", "h1gh", "h1ll", "h1nt", "h1p", "h1r3", "h15t0ry", "h0bby", "h0ck3y", "h0ld", "h0l3", "h0l1day", "h0ll0w", "h0m3", "h0n3y", "h00d", "h0p3", "h0rn", "h0rr0r", "h0r53", "h05p1tal", "h05t", "h0t3l", "h0ur", "h0v3r", "hub", "hug3", "human", "humbl3", "hum0r", "hundr3d", "hungry", "hunt", "hurdl3", "hurry", "hurt", "hu5band", "hybr1d", "1c3", "1c0n", "1d3a", "1d3nt1fy", "1dl3", "1gn0r3", "1ll", "1ll3gal", "1lln355", "1mag3", "1m1tat3", "1mm3n53", "1mmun3", "1mpact", "1mp053", "1mpr0v3", "1mpul53", "1nch", "1nclud3", "1nc0m3", "1ncr3a53", "1nd3x", "1nd1cat3", "1nd00r", "1ndu5try", "1nfant", "1nfl1ct", "1nf0rm", "1nhal3", "1nh3r1t", "1n1t1al", "1nj3ct", "1njury", "1nmat3", "1nn3r", "1nn0c3nt", "1nput", "1nqu1ry", "1n5an3", "1n53ct", "1n51d3", "1n5p1r3", "1n5tall", "1ntact", "1nt3r35t", "1nt0", "1nv35t", "1nv1t3", "1nv0lv3", "1r0n", "15land", "150lat3", "155u3", "1t3m", "1v0ry", "jack3t", "jaguar", "jar", "jazz", "j3al0u5", "j3an5", "j3lly", "j3w3l", "j0b", "j01n", "j0k3", "j0urn3y", "j0y", "judg3", "ju1c3", "jump", "jungl3", "jun10r", "junk", "ju5t", "kangar00", "k33n", "k33p", "k3tchup", "k3y", "k1ck", "k1d", "k1dn3y", "k1nd", "k1ngd0m", "k155", "k1t", "k1tch3n", "k1t3", "k1tt3n", "k1w1", "kn33", "kn1f3", "kn0ck", "kn0w", "lab", "lab3l", "lab0r", "ladd3r", "lady", "lak3", "lamp", "languag3", "lapt0p", "larg3", "lat3r", "lat1n", "laugh", "laundry", "lava", "law", "lawn", "law5u1t", "lay3r", "lazy", "l3ad3r", "l3af", "l3arn", "l3av3", "l3ctur3", "l3ft", "l3g", "l3gal", "l3g3nd", "l315ur3", "l3m0n", "l3nd", "l3ngth", "l3n5", "l30pard", "l3550n", "l3tt3r", "l3v3l", "l1ar", "l1b3rty", "l1brary", "l1c3n53", "l1f3", "l1ft", "l1ght", "l1k3", "l1mb", "l1m1t", "l1nk", "l10n", "l1qu1d", "l15t", "l1ttl3", "l1v3", "l1zard", "l0ad", "l0an", "l0b5t3r", "l0cal", "l0ck", "l0g1c", "l0n3ly", "l0ng", "l00p", "l0tt3ry", "l0ud", "l0ung3", "l0v3", "l0yal", "lucky", "luggag3", "lumb3r", "lunar", "lunch", "luxury", "lyr1c5", "mach1n3", "mad", "mag1c", "magn3t", "ma1d", "ma1l", "ma1n", "maj0r", "mak3", "mammal", "man", "manag3", "mandat3", "mang0", "man510n", "manual", "mapl3", "marbl3", "march", "marg1n", "mar1n3", "mark3t", "marr1ag3", "ma5k", "ma55", "ma5t3r", "match", "mat3r1al", "math", "matr1x", "matt3r", "max1mum", "maz3", "m3ad0w", "m3an", "m3a5ur3", "m3at", "m3chan1c", "m3dal", "m3d1a", "m3l0dy", "m3lt", "m3mb3r", "m3m0ry", "m3nt10n", "m3nu", "m3rcy", "m3rg3", "m3r1t", "m3rry", "m35h", "m355ag3", "m3tal", "m3th0d", "m1ddl3", "m1dn1ght", "m1lk", "m1ll10n", "m1m1c", "m1nd", "m1n1mum", "m1n0r", "m1nut3", "m1racl3", "m1rr0r", "m153ry", "m155", "m15tak3", "m1x", "m1x3d", "m1xtur3", "m0b1l3", "m0d3l", "m0d1fy", "m0m", "m0m3nt", "m0n1t0r", "m0nk3y", "m0n5t3r", "m0nth", "m00n", "m0ral", "m0r3", "m0rn1ng", "m05qu1t0", "m0th3r", "m0t10n", "m0t0r", "m0unta1n", "m0u53", "m0v3", "m0v13", "much", "muff1n", "mul3", "mult1ply", "mu5cl3", "mu53um", "mu5hr00m", "mu51c", "mu5t", "mutual", "my53lf", "my5t3ry", "myth", "na1v3", "nam3", "napk1n", "narr0w", "na5ty", "nat10n", "natur3", "n3ar", "n3ck", "n33d", "n3gat1v3", "n3gl3ct", "n31th3r", "n3ph3w", "n3rv3", "n35t", "n3t", "n3tw0rk", "n3utral", "n3v3r", "n3w5", "n3xt", "n1c3", "n1ght", "n0bl3", "n0153", "n0m1n33", "n00dl3", "n0rmal", "n0rth", "n053", "n0tabl3", "n0t3", "n0th1ng", "n0t1c3", "n0v3l", "n0w", "nucl3ar", "numb3r", "nur53", "nut", "0ak", "0b3y", "0bj3ct", "0bl1g3", "0b5cur3", "0b53rv3", "0bta1n", "0bv10u5", "0ccur", "0c3an", "0ct0b3r", "0d0r", "0ff", "0ff3r", "0ff1c3", "0ft3n", "01l", "0kay", "0ld", "0l1v3", "0lymp1c", "0m1t", "0nc3", "0n3", "0n10n", "0nl1n3", "0nly", "0p3n", "0p3ra", "0p1n10n", "0pp053", "0pt10n", "0rang3", "0rb1t", "0rchard", "0rd3r", "0rd1nary", "0rgan", "0r13nt", "0r1g1nal", "0rphan", "05tr1ch", "0th3r", "0utd00r", "0ut3r", "0utput", "0ut51d3", "0val", "0v3n", "0v3r", "0wn", "0wn3r", "0xyg3n", "0y5t3r", "0z0n3", "pact", "paddl3", "pag3", "pa1r", "palac3", "palm", "panda", "pan3l", "pan1c", "panth3r", "pap3r", "parad3", "par3nt", "park", "parr0t", "party", "pa55", "patch", "path", "pat13nt", "patr0l", "patt3rn", "pau53", "pav3", "paym3nt", "p3ac3", "p3anut", "p3ar", "p3a5ant", "p3l1can", "p3n", "p3nalty", "p3nc1l", "p30pl3", "p3pp3r", "p3rf3ct", "p3rm1t", "p3r50n", "p3t", "ph0n3", "ph0t0", "phra53", "phy51cal", "p1an0", "p1cn1c", "p1ctur3", "p13c3", "p1g", "p1g30n", "p1ll", "p1l0t", "p1nk", "p10n33r", "p1p3", "p15t0l", "p1tch", "p1zza", "plac3", "plan3t", "pla5t1c", "plat3", "play", "pl3a53", "pl3dg3", "pluck", "plug", "plung3", "p03m", "p03t", "p01nt", "p0lar", "p0l3", "p0l1c3", "p0nd", "p0ny", "p00l", "p0pular", "p0rt10n", "p051t10n", "p0551bl3", "p05t", "p0tat0", "p0tt3ry", "p0v3rty", "p0wd3r", "p0w3r", "pract1c3", "pra153", "pr3d1ct", "pr3f3r", "pr3par3", "pr353nt", "pr3tty", "pr3v3nt", "pr1c3", "pr1d3", "pr1mary", "pr1nt", "pr10r1ty", "pr150n", "pr1vat3", "pr1z3", "pr0bl3m", "pr0c355", "pr0duc3", "pr0f1t", "pr0gram", "pr0j3ct", "pr0m0t3", "pr00f", "pr0p3rty", "pr05p3r", "pr0t3ct", "pr0ud", "pr0v1d3", "publ1c", "pudd1ng", "pull", "pulp", "pul53", "pumpk1n", "punch", "pup1l", "puppy", "purcha53", "pur1ty", "purp053", "pur53", "pu5h", "put", "puzzl3", "pyram1d", "qual1ty", "quantum", "quart3r", "qu35t10n", "qu1ck", "qu1t", "qu1z", "qu0t3", "rabb1t", "racc00n", "rac3", "rack", "radar", "rad10", "ra1l", "ra1n", "ra153", "rally", "ramp", "ranch", "rand0m", "rang3", "rap1d", "rar3", "rat3", "rath3r", "rav3n", "raw", "raz0r", "r3ady", "r3al", "r3a50n", "r3b3l", "r3bu1ld", "r3call", "r3c31v3", "r3c1p3", "r3c0rd", "r3cycl3", "r3duc3", "r3fl3ct", "r3f0rm", "r3fu53", "r3g10n", "r3gr3t", "r3gular", "r3j3ct", "r3lax", "r3l3a53", "r3l13f", "r3ly", "r3ma1n", "r3m3mb3r", "r3m1nd", "r3m0v3", "r3nd3r", "r3n3w", "r3nt", "r30p3n", "r3pa1r", "r3p3at", "r3plac3", "r3p0rt", "r3qu1r3", "r35cu3", "r353mbl3", "r3515t", "r350urc3", "r35p0n53", "r35ult", "r3t1r3", "r3tr3at", "r3turn", "r3un10n", "r3v3al", "r3v13w", "r3ward", "rhythm", "r1b", "r1bb0n", "r1c3", "r1ch", "r1d3", "r1dg3", "r1fl3", "r1ght", "r1g1d", "r1ng", "r10t", "r1ppl3", "r15k", "r1tual", "r1val", "r1v3r", "r0ad", "r0a5t", "r0b0t", "r0bu5t", "r0ck3t", "r0manc3", "r00f", "r00k13", "r00m", "r053", "r0tat3", "r0ugh", "r0und", "r0ut3", "r0yal", "rubb3r", "rud3", "rug", "rul3", "run", "runway", "rural", "5ad", "5addl3", "5adn355", "5af3", "5a1l", "5alad", "5alm0n", "5al0n", "5alt", "5alut3", "5am3", "5ampl3", "5and", "5at15fy", "5at05h1", "5auc3", "5au5ag3", "5av3", "5ay", "5cal3", "5can", "5car3", "5catt3r", "5c3n3", "5ch3m3", "5ch00l", "5c13nc3", "5c1550r5", "5c0rp10n", "5c0ut", "5crap", "5cr33n", "5cr1pt", "5crub", "53a", "53arch", "53a50n", "53at", "53c0nd", "53cr3t", "53ct10n", "53cur1ty", "533d", "533k", "53gm3nt", "53l3ct", "53ll", "53m1nar", "53n10r", "53n53", "53nt3nc3", "53r135", "53rv1c3", "535510n", "53ttl3", "53tup", "53v3n", "5had0w", "5haft", "5hall0w", "5har3", "5h3d", "5h3ll", "5h3r1ff", "5h13ld", "5h1ft", "5h1n3", "5h1p", "5h1v3r", "5h0ck", "5h03", "5h00t", "5h0p", "5h0rt", "5h0uld3r", "5h0v3", "5hr1mp", "5hrug", "5huffl3", "5hy", "51bl1ng", "51ck", "51d3", "513g3", "51ght", "51gn", "51l3nt", "51lk", "51lly", "51lv3r", "51m1lar", "51mpl3", "51nc3", "51ng", "51r3n", "515t3r", "51tuat3", "51x", "51z3", "5kat3", "5k3tch", "5k1", "5k1ll", "5k1n", "5k1rt", "5kull", "5lab", "5lam", "5l33p", "5l3nd3r", "5l1c3", "5l1d3", "5l1ght", "5l1m", "5l0gan", "5l0t", "5l0w", "5lu5h", "5mall", "5mart", "5m1l3", "5m0k3", "5m00th", "5nack", "5nak3", "5nap", "5n1ff", "5n0w", "50ap", "50cc3r", "50c1al", "50ck", "50da", "50ft", "50lar", "50ld13r", "50l1d", "50lut10n", "50lv3", "50m30n3", "50ng", "500n", "50rry", "50rt", "50ul", "50und", "50up", "50urc3", "50uth", "5pac3", "5par3", "5pat1al", "5pawn", "5p3ak", "5p3c1al", "5p33d", "5p3ll", "5p3nd", "5ph3r3", "5p1c3", "5p1d3r", "5p1k3", "5p1n", "5p1r1t", "5pl1t", "5p01l", "5p0n50r", "5p00n", "5p0rt", "5p0t", "5pray", "5pr3ad", "5pr1ng", "5py", "5quar3", "5qu33z3", "5qu1rr3l", "5tabl3", "5tad1um", "5taff", "5tag3", "5ta1r5", "5tamp", "5tand", "5tart", "5tat3", "5tay", "5t3ak", "5t33l", "5t3m", "5t3p", "5t3r30", "5t1ck", "5t1ll", "5t1ng", "5t0ck", "5t0mach", "5t0n3", "5t00l", "5t0ry", "5t0v3", "5trat3gy", "5tr33t", "5tr1k3", "5tr0ng", "5truggl3", "5tud3nt", "5tuff", "5tumbl3", "5tyl3", "5ubj3ct", "5ubm1t", "5ubway", "5ucc355", "5uch", "5udd3n", "5uff3r", "5ugar", "5ugg35t", "5u1t", "5umm3r", "5un", "5unny", "5un53t", "5up3r", "5upply", "5upr3m3", "5ur3", "5urfac3", "5urg3", "5urpr153", "5urr0und", "5urv3y", "5u5p3ct", "5u5ta1n", "5wall0w", "5wamp", "5wap", "5warm", "5w3ar", "5w33t", "5w1ft", "5w1m", "5w1ng", "5w1tch", "5w0rd", "5ymb0l", "5ympt0m", "5yrup", "5y5t3m", "tabl3", "tackl3", "tag", "ta1l", "tal3nt", "talk", "tank", "tap3", "targ3t", "ta5k", "ta5t3", "tatt00", "tax1", "t3ach", "t3am", "t3ll", "t3n", "t3nant", "t3nn15", "t3nt", "t3rm", "t35t", "t3xt", "thank", "that", "th3m3", "th3n", "th30ry", "th3r3", "th3y", "th1ng", "th15", "th0ught", "thr33", "thr1v3", "thr0w", "thumb", "thund3r", "t1ck3t", "t1d3", "t1g3r", "t1lt", "t1mb3r", "t1m3", "t1ny", "t1p", "t1r3d", "t155u3", "t1tl3", "t0a5t", "t0bacc0", "t0day", "t0ddl3r", "t03", "t0g3th3r", "t01l3t", "t0k3n", "t0mat0", "t0m0rr0w", "t0n3", "t0ngu3", "t0n1ght", "t00l", "t00th", "t0p", "t0p1c", "t0ppl3", "t0rch", "t0rnad0", "t0rt0153", "t055", "t0tal", "t0ur15t", "t0ward", "t0w3r", "t0wn", "t0y", "track", "trad3", "traff1c", "trag1c", "tra1n", "tran5f3r", "trap", "tra5h", "trav3l", "tray", "tr3at", "tr33", "tr3nd", "tr1al", "tr1b3", "tr1ck", "tr1gg3r", "tr1m", "tr1p", "tr0phy", "tr0ubl3", "truck", "tru3", "truly", "trump3t", "tru5t", "truth", "try", "tub3", "tu1t10n", "tumbl3", "tuna", "tunn3l", "turk3y", "turn", "turtl3", "tw3lv3", "tw3nty", "tw1c3", "tw1n", "tw15t", "tw0", "typ3", "typ1cal", "ugly", "umbr3lla", "unabl3", "unawar3", "uncl3", "unc0v3r", "und3r", "und0", "unfa1r", "unf0ld", "unhappy", "un1f0rm", "un1qu3", "un1t", "un1v3r53", "unkn0wn", "unl0ck", "unt1l", "unu5ual", "unv31l", "updat3", "upgrad3", "uph0ld", "up0n", "upp3r", "up53t", "urban", "urg3", "u5ag3", "u53", "u53d", "u53ful", "u53l355", "u5ual", "ut1l1ty", "vacant", "vacuum", "vagu3", "val1d", "vall3y", "valv3", "van", "van15h", "vap0r", "var10u5", "va5t", "vault", "v3h1cl3", "v3lv3t", "v3nd0r", "v3ntur3", "v3nu3", "v3rb", "v3r1fy", "v3r510n", "v3ry", "v3553l", "v3t3ran", "v1abl3", "v1brant", "v1c10u5", "v1ct0ry", "v1d30", "v13w", "v1llag3", "v1ntag3", "v10l1n", "v1rtual", "v1ru5", "v15a", "v151t", "v15ual", "v1tal", "v1v1d", "v0cal", "v01c3", "v01d", "v0lcan0", "v0lum3", "v0t3", "v0yag3", "wag3", "wag0n", "wa1t", "walk", "wall", "walnut", "want", "warfar3", "warm", "warr10r", "wa5h", "wa5p", "wa5t3", "wat3r", "wav3", "way", "w3alth", "w3ap0n", "w3ar", "w3a53l", "w3ath3r", "w3b", "w3dd1ng", "w33k3nd", "w31rd", "w3lc0m3", "w35t", "w3t", "whal3", "what", "wh3at", "wh33l", "wh3n", "wh3r3", "wh1p", "wh15p3r", "w1d3", "w1dth", "w1f3", "w1ld", "w1ll", "w1n", "w1nd0w", "w1n3", "w1ng", "w1nk", "w1nn3r", "w1nt3r", "w1r3", "w15d0m", "w153", "w15h", "w1tn355", "w0lf", "w0man", "w0nd3r", "w00d", "w00l", "w0rd", "w0rk", "w0rld", "w0rry", "w0rth", "wrap", "wr3ck", "wr35tl3", "wr15t", "wr1t3", "wr0ng", "yard", "y3ar", "y3ll0w", "y0u", "y0ung", "y0uth", "z3bra", "z3r0", "z0n3", "z00"])
    let vector: [TestVector] = [
      TestVector(language: .english,
                 "00000000000000000000000000000000",
                 "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about",
                 "c55257c360c07c72029aebc1b53c05ed0362ada38ead3e3e9efa3708e53495531f09a6987599d18264c1e1c92f2cf141630c7a3c4ab7c81b2f001698e7463b04",
                 "TREZOR"),
      TestVector(language: .english,
                 "7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f",
                 "legal winner thank year wave sausage worth useful legal winner thank yellow",
                 "2e8905819b8723fe2c1d161860e5ee1830318dbf49a83bd451cfb8440c28bd6fa457fe1296106559a3c80937a1c1069be3a3a5bd381ee6260e8d9739fce1f607",
                 "TREZOR"),
      TestVector(language: .english,
                 "80808080808080808080808080808080",
                 "letter advice cage absurd amount doctor acoustic avoid letter advice cage above",
                 "d71de856f81a8acc65e6fc851a38d4d7ec216fd0796d0a6827a3ad6ed5511a30fa280f12eb2e47ed2ac03b5c462a0358d18d69fe4f985ec81778c1b370b652a8",
                 "TREZOR"),
      TestVector(language: .english,
                 "ffffffffffffffffffffffffffffffff",
                 "zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo wrong",
                 "ac27495480225222079d7be181583751e86f571027b0497b5b5d11218e0a8a13332572917f0f8e5a589620c6f15b11c61dee327651a14c34e18231052e48c069",
                 "TREZOR"),
      TestVector(language: .english,
                 "000000000000000000000000000000000000000000000000",
                 "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon agent",
                 "035895f2f481b1b0f01fcf8c289c794660b289981a78f8106447707fdd9666ca06da5a9a565181599b79f53b844d8a71dd9f439c52a3d7b3e8a79c906ac845fa",
                 "TREZOR"),
      TestVector(language: .english,
                 "7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f",
                 "legal winner thank year wave sausage worth useful legal winner thank year wave sausage worth useful legal will",
                 "f2b94508732bcbacbcc020faefecfc89feafa6649a5491b8c952cede496c214a0c7b3c392d168748f2d4a612bada0753b52a1c7ac53c1e93abd5c6320b9e95dd",
                 "TREZOR"),
      TestVector(language: .english,
                 "808080808080808080808080808080808080808080808080",
                 "letter advice cage absurd amount doctor acoustic avoid letter advice cage absurd amount doctor acoustic avoid letter always",
                 "107d7c02a5aa6f38c58083ff74f04c607c2d2c0ecc55501dadd72d025b751bc27fe913ffb796f841c49b1d33b610cf0e91d3aa239027f5e99fe4ce9e5088cd65",
                 "TREZOR"),
      TestVector(language: .english,
                 "ffffffffffffffffffffffffffffffffffffffffffffffff",
                 "zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo when",
                 "0cd6e5d827bb62eb8fc1e262254223817fd068a74b5b449cc2f667c3f1f985a76379b43348d952e2265b4cd129090758b3e3c2c49103b5051aac2eaeb890a528",
                 "TREZOR"),
      TestVector(language: .english,
                 "0000000000000000000000000000000000000000000000000000000000000000",
                 "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon art",
                 "bda85446c68413707090a52022edd26a1c9462295029f2e60cd7c4f2bbd3097170af7a4d73245cafa9c3cca8d561a7c3de6f5d4a10be8ed2a5e608d68f92fcc8",
                 "TREZOR"),
      TestVector(language: .english,
                 "7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f",
                 "legal winner thank year wave sausage worth useful legal winner thank year wave sausage worth useful legal winner thank year wave sausage worth title",
                 "bc09fca1804f7e69da93c2f2028eb238c227f2e9dda30cd63699232578480a4021b146ad717fbb7e451ce9eb835f43620bf5c514db0f8add49f5d121449d3e87",
                 "TREZOR"),
      TestVector(language: .english,
                 "8080808080808080808080808080808080808080808080808080808080808080",
                 "letter advice cage absurd amount doctor acoustic avoid letter advice cage absurd amount doctor acoustic avoid letter advice cage absurd amount doctor acoustic bless",
                 "c0c519bd0e91a2ed54357d9d1ebef6f5af218a153624cf4f2da911a0ed8f7a09e2ef61af0aca007096df430022f7a2b6fb91661a9589097069720d015e4e982f",
                 "TREZOR"),
      TestVector(language: .english,
                 "ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff",
                 "zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo vote",
                 "dd48c104698c30cfe2b6142103248622fb7bb0ff692eebb00089b32d22484e1613912f0a5b694407be899ffd31ed3992c456cdf60f5d4564b8ba3f05a69890ad",
                 "TREZOR"),
      TestVector(language: .english,
                 "9e885d952ad362caeb4efe34a8e91bd2",
                 "ozone drill grab fiber curtain grace pudding thank cruise elder eight picnic",
                 "274ddc525802f7c828d8ef7ddbcdc5304e87ac3535913611fbbfa986d0c9e5476c91689f9c8a54fd55bd38606aa6a8595ad213d4c9c9f9aca3fb217069a41028",
                 "TREZOR"),
      TestVector(language: .english,
                 "6610b25967cdcca9d59875f5cb50b0ea75433311869e930b",
                 "gravity machine north sort system female filter attitude volume fold club stay feature office ecology stable narrow fog",
                 "628c3827a8823298ee685db84f55caa34b5cc195a778e52d45f59bcf75aba68e4d7590e101dc414bc1bbd5737666fbbef35d1f1903953b66624f910feef245ac",
                 "TREZOR"),
      TestVector(language: .english,
                 "68a79eaca2324873eacc50cb9c6eca8cc68ea5d936f98787c60c7ebc74e6ce7c",
                 "hamster diagram private dutch cause delay private meat slide toddler razor book happy fancy gospel tennis maple dilemma loan word shrug inflict delay length",
                 "64c87cde7e12ecf6704ab95bb1408bef047c22db4cc7491c4271d170a1b213d20b385bc1588d9c7b38f1b39d415665b8a9030c9ec653d75e65f847d8fc1fc440",
                 "TREZOR"),
      TestVector(language: .english,
                 "c0ba5a8e914111210f2bd131f3d5e08d",
                 "scheme spot photo card baby mountain device kick cradle pact join borrow",
                 "ea725895aaae8d4c1cf682c1bfd2d358d52ed9f0f0591131b559e2724bb234fca05aa9c02c57407e04ee9dc3b454aa63fbff483a8b11de949624b9f1831a9612",
                 "TREZOR"),
      TestVector(language: .english,
                 "6d9be1ee6ebd27a258115aad99b7317b9c8d28b6d76431c3",
                 "horn tenant knee talent sponsor spell gate clip pulse soap slush warm silver nephew swap uncle crack brave",
                 "fd579828af3da1d32544ce4db5c73d53fc8acc4ddb1e3b251a31179cdb71e853c56d2fcb11aed39898ce6c34b10b5382772db8796e52837b54468aeb312cfc3d",
                 "TREZOR"),
      TestVector(language: .english,
                 "9f6a2878b2520799a44ef18bc7df394e7061a224d2c33cd015b157d746869863",
                 "panda eyebrow bullet gorilla call smoke muffin taste mesh discover soft ostrich alcohol speed nation flash devote level hobby quick inner drive ghost inside",
                 "72be8e052fc4919d2adf28d5306b5474b0069df35b02303de8c1729c9538dbb6fc2d731d5f832193cd9fb6aeecbc469594a70e3dd50811b5067f3b88b28c3e8d",
                 "TREZOR"),
      TestVector(language: .english,
                 "23db8160a31d3e0dca3688ed941adbf3",
                 "cat swing flag economy stadium alone churn speed unique patch report train",
                 "deb5f45449e615feff5640f2e49f933ff51895de3b4381832b3139941c57b59205a42480c52175b6efcffaa58a2503887c1e8b363a707256bdd2b587b46541f5",
                 "TREZOR"),
      TestVector(language: .english,
                 "8197a4a47f0425faeaa69deebc05ca29c0a5b5cc76ceacc0",
                 "light rule cinnamon wrap drastic word pride squirrel upgrade then income fatal apart sustain crack supply proud access",
                 "4cbdff1ca2db800fd61cae72a57475fdc6bab03e441fd63f96dabd1f183ef5b782925f00105f318309a7e9c3ea6967c7801e46c8a58082674c860a37b93eda02",
                 "TREZOR"),
      TestVector(language: .english,
                 "066dca1a2bb7e8a1db2832148ce9933eea0f3ac9548d793112d9a95c9407efad",
                 "all hour make first leader extend hole alien behind guard gospel lava path output census museum junior mass reopen famous sing advance salt reform",
                 "26e975ec644423f4a4c4f4215ef09b4bd7ef924e85d1d17c4cf3f136c2863cf6df0a475045652c57eb5fb41513ca2a2d67722b77e954b4b3fc11f7590449191d",
                 "TREZOR"),
      TestVector(language: .english,
                 "f30f8c1da665478f49b001d94c5fc452",
                 "vessel ladder alter error federal sibling chat ability sun glass valve picture",
                 "2aaa9242daafcee6aa9d7269f17d4efe271e1b9a529178d7dc139cd18747090bf9d60295d0ce74309a78852a9caadf0af48aae1c6253839624076224374bc63f",
                 "TREZOR"),
      TestVector(language: .english,
                 "c10ec20dc3cd9f652c7fac2f1230f7a3c828389a14392f05",
                 "scissors invite lock maple supreme raw rapid void congress muscle digital elegant little brisk hair mango congress clump",
                 "7b4a10be9d98e6cba265566db7f136718e1398c71cb581e1b2f464cac1ceedf4f3e274dc270003c670ad8d02c4558b2f8e39edea2775c9e232c7cb798b069e88",
                 "TREZOR"),
      TestVector(language: .english,
                 "f585c11aec520db57dd353c69554b21a89b20fb0650966fa0a9d6f74fd989d8f",
                 "void come effort suffer camp survey warrior heavy shoot primary clutch crush open amazing screen patrol group space point ten exist slush involve unfold",
                 "01f5bced59dec48e362f2c45b5de68b9fd6c92c6634f44d6d40aab69056506f0e35524a518034ddc1192e1dacd32c1ed3eaa3c3b131c88ed8e7e54c49a5d0998",
                 "TREZOR"),
      TestVector(language: .english,
                 "77c2b00716cec7213839159e404db50d",
                 "jelly better achieve collect unaware mountain thought cargo oxygen act hood bridge",
                 "b5b6d0127db1a9d2226af0c3346031d77af31e918dba64287a1b44b8ebf63cdd52676f672a290aae502472cf2d602c051f3e6f18055e84e4c43897fc4e51a6ff",
                 "TREZOR"),
      TestVector(language: .english,
                 "b63a9c59a6e641f288ebc103017f1da9f8290b3da6bdef7b",
                 "renew stay biology evidence goat welcome casual join adapt armor shuffle fault little machine walk stumble urge swap",
                 "9248d83e06f4cd98debf5b6f010542760df925ce46cf38a1bdb4e4de7d21f5c39366941c69e1bdbf2966e0f6e6dbece898a0e2f0a4c2b3e640953dfe8b7bbdc5",
                 "TREZOR"),
      TestVector(language: .english,
                 "3e141609b97933b66a060dcddc71fad1d91677db872031e85f4c015c5e7e8982",
                 "dignity pass list indicate nasty swamp pool script soccer toe leaf photo multiply desk host tomato cradle drill spread actor shine dismiss champion exotic",
                 "ff7f3184df8696d8bef94b6c03114dbee0ef89ff938712301d27ed8336ca89ef9635da20af07d4175f2bf5f3de130f39c9d9e8dd0472489c19b1a020a940da67",
                 "TREZOR"),
      TestVector(language: .english,
                 "0460ef47585604c5660618db2e6a7e7f",
                 "afford alter spike radar gate glance object seek swamp infant panel yellow",
                 "65f93a9f36b6c85cbe634ffc1f99f2b82cbb10b31edc7f087b4f6cb9e976e9faf76ff41f8f27c99afdf38f7a303ba1136ee48a4c1e7fcd3dba7aa876113a36e4",
                 "TREZOR"),
      TestVector(language: .english,
                 "72f60ebac5dd8add8d2a25a797102c3ce21bc029c200076f",
                 "indicate race push merry suffer human cruise dwarf pole review arch keep canvas theme poem divorce alter left",
                 "3bbf9daa0dfad8229786ace5ddb4e00fa98a044ae4c4975ffd5e094dba9e0bb289349dbe2091761f30f382d4e35c4a670ee8ab50758d2c55881be69e327117ba",
                 "TREZOR"),
      TestVector(language: .english,
                 "2c85efc7f24ee4573d2b81a6ec66cee209b2dcbd09d8eddc51e0215b0b68e416",
                 "clutch control vehicle tonight unusual clog visa ice plunge glimpse recipe series open hour vintage deposit universe tip job dress radar refuse motion taste",
                 "fe908f96f46668b2d5b37d82f558c77ed0d69dd0e7e043a5b0511c48c2f1064694a956f86360c93dd04052a8899497ce9e985ebe0c8c52b955e6ae86d4ff4449",
                 "TREZOR"),
      TestVector(language: .english,
                 "eaebabb2383351fd31d703840b32e9e2",
                 "turtle front uncle idea crush write shrug there lottery flower risk shell",
                 "bdfb76a0759f301b0b899a1e3985227e53b3f51e67e3f2a65363caedf3e32fde42a66c404f18d7b05818c95ef3ca1e5146646856c461c073169467511680876c",
                 "TREZOR"),
      TestVector(language: .english,
                 "7ac45cfe7722ee6c7ba84fbc2d5bd61b45cb2fe5eb65aa78",
                 "kiss carry display unusual confirm curtain upgrade antique rotate hello void custom frequent obey nut hole price segment",
                 "ed56ff6c833c07982eb7119a8f48fd363c4a9b1601cd2de736b01045c5eb8ab4f57b079403485d1c4924f0790dc10a971763337cb9f9c62226f64fff26397c79",
                 "TREZOR"),
      TestVector(language: .english,
                 "4fa1a8bc3e6d80ee1316050e862c1812031493212b7ec3f3bb1b08f168cabeef",
                 "exile ask congress lamp submit jacket era scheme attend cousin alcohol catch course end lucky hurt sentence oven short ball bird grab wing top",
                 "095ee6f817b4c2cb30a5a797360a81a40ab0f9a4e25ecd672a3f58a0b5ba0687c096a6b14d2c0deb3bdefce4f61d01ae07417d502429352e27695163f7447a8c",
                 "TREZOR"),
      TestVector(language: .english,
                 "18ab19a9f54a9274f03e5209a2ac8a91",
                 "board flee heavy tunnel powder denial science ski answer betray cargo cat",
                 "6eff1bb21562918509c73cb990260db07c0ce34ff0e3cc4a8cb3276129fbcb300bddfe005831350efd633909f476c45c88253276d9fd0df6ef48609e8bb7dca8",
                 "TREZOR"),
      TestVector(language: .english,
                 "18a2e1d81b8ecfb2a333adcb0c17a5b9eb76cc5d05db91a4",
                 "board blade invite damage undo sun mimic interest slam gaze truly inherit resist great inject rocket museum chief",
                 "f84521c777a13b61564234bf8f8b62b3afce27fc4062b51bb5e62bdfecb23864ee6ecf07c1d5a97c0834307c5c852d8ceb88e7c97923c0a3b496bedd4e5f88a9",
                 "TREZOR"),
      TestVector(language: .english,
                 "15da872c95a13dd738fbf50e427583ad61f18fd99f628c417a61cf8343c90419",
                 "beyond stage sleep clip because twist token leaf atom beauty genius food business side grid unable middle armed observe pair crouch tonight away coconut",
                 "b15509eaa2d09d3efd3e006ef42151b30367dc6e3aa5e44caba3fe4d3e352e65101fbdb86a96776b91946ff06f8eac594dc6ee1d3e82a42dfe1b40fef6bcc3fd",
                 "TREZOR"),
      TestVector(language: .japanese,
                 "00000000000000000000000000000000",
                 "あいこくしん　あいこくしん　あいこくしん　あいこくしん　あいこくしん　あいこくしん　あいこくしん　あいこくしん　あいこくしん　あいこくしん　あいこくしん　あおぞら",
                 "a262d6fb6122ecf45be09c50492b31f92e9beb7d9a845987a02cefda57a15f9c467a17872029a9e92299b5cbdf306e3a0ee620245cbd508959b6cb7ca637bd55"),
      TestVector(language: .japanese,
                 "7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f",
                 "そつう　れきだい　ほんやく　わかす　りくつ　ばいか　ろせん　やちん　そつう　れきだい　ほんやく　わかめ",
                 "aee025cbe6ca256862f889e48110a6a382365142f7d16f2b9545285b3af64e542143a577e9c144e101a6bdca18f8d97ec3366ebf5b088b1c1af9bc31346e60d9"),
      TestVector(language: .japanese,
                 "80808080808080808080808080808080",
                 "そとづら　あまど　おおう　あこがれる　いくぶん　けいけん　あたえる　いよく　そとづら　あまど　おおう　あかちゃん",
                 "e51736736ebdf77eda23fa17e31475fa1d9509c78f1deb6b4aacfbd760a7e2ad769c714352c95143b5c1241985bcb407df36d64e75dd5a2b78ca5d2ba82a3544"),
      TestVector(language: .japanese,
                 "ffffffffffffffffffffffffffffffff",
                 "われる　われる　われる　われる　われる　われる　われる　われる　われる　われる　われる　ろんぶん",
                 "4cd2ef49b479af5e1efbbd1e0bdc117f6a29b1010211df4f78e2ed40082865793e57949236c43b9fe591ec70e5bb4298b8b71dc4b267bb96ed4ed282c8f7761c"),
      TestVector(language: .japanese,
                 "000000000000000000000000000000000000000000000000",
                 "あいこくしん　あいこくしん　あいこくしん　あいこくしん　あいこくしん　あいこくしん　あいこくしん　あいこくしん　あいこくしん　あいこくしん　あいこくしん　あいこくしん　あいこくしん　あいこくしん　あいこくしん　あいこくしん　あいこくしん　あらいぐま",
                 "d99e8f1ce2d4288d30b9c815ae981edd923c01aa4ffdc5dee1ab5fe0d4a3e13966023324d119105aff266dac32e5cd11431eeca23bbd7202ff423f30d6776d69"),
      TestVector(language: .japanese,
                 "7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f",
                 "そつう　れきだい　ほんやく　わかす　りくつ　ばいか　ろせん　やちん　そつう　れきだい　ほんやく　わかす　りくつ　ばいか　ろせん　やちん　そつう　れいぎ",
                 "eaaf171efa5de4838c758a93d6c86d2677d4ccda4a064a7136344e975f91fe61340ec8a615464b461d67baaf12b62ab5e742f944c7bd4ab6c341fbafba435716"),
      TestVector(language: .japanese,
                 "808080808080808080808080808080808080808080808080",
                 "そとづら　あまど　おおう　あこがれる　いくぶん　けいけん　あたえる　いよく　そとづら　あまど　おおう　あこがれる　いくぶん　けいけん　あたえる　いよく　そとづら　いきなり",
                 "aec0f8d3167a10683374c222e6e632f2940c0826587ea0a73ac5d0493b6a632590179a6538287641a9fc9df8e6f24e01bf1be548e1f74fd7407ccd72ecebe425"),
      TestVector(language: .japanese,
                 "ffffffffffffffffffffffffffffffffffffffffffffffff",
                 "われる　われる　われる　われる　われる　われる　われる　われる　われる　われる　われる　われる　われる　われる　われる　われる　われる　りんご",
                 "f0f738128a65b8d1854d68de50ed97ac1831fc3a978c569e415bbcb431a6a671d4377e3b56abd518daa861676c4da75a19ccb41e00c37d086941e471a4374b95"),
      TestVector(language: .japanese,
                 "0000000000000000000000000000000000000000000000000000000000000000",
                 "あいこくしん　あいこくしん　あいこくしん　あいこくしん　あいこくしん　あいこくしん　あいこくしん　あいこくしん　あいこくしん　あいこくしん　あいこくしん　あいこくしん　あいこくしん　あいこくしん　あいこくしん　あいこくしん　あいこくしん　あいこくしん　あいこくしん　あいこくしん　あいこくしん　あいこくしん　あいこくしん　いってい",
                 "23f500eec4a563bf90cfda87b3e590b211b959985c555d17e88f46f7183590cd5793458b094a4dccc8f05807ec7bd2d19ce269e20568936a751f6f1ec7c14ddd"),
      TestVector(language: .japanese,
                 "7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f",
                 "そつう　れきだい　ほんやく　わかす　りくつ　ばいか　ろせん　やちん　そつう　れきだい　ほんやく　わかす　りくつ　ばいか　ろせん　やちん　そつう　れきだい　ほんやく　わかす　りくつ　ばいか　ろせん　まんきつ",
                 "cd354a40aa2e241e8f306b3b752781b70dfd1c69190e510bc1297a9c5738e833bcdc179e81707d57263fb7564466f73d30bf979725ff783fb3eb4baa86560b05"),
      TestVector(language: .japanese,
                 "8080808080808080808080808080808080808080808080808080808080808080",
                 "そとづら　あまど　おおう　あこがれる　いくぶん　けいけん　あたえる　いよく　そとづら　あまど　おおう　あこがれる　いくぶん　けいけん　あたえる　いよく　そとづら　あまど　おおう　あこがれる　いくぶん　けいけん　あたえる　うめる",
                 "6b7cd1b2cdfeeef8615077cadd6a0625f417f287652991c80206dbd82db17bf317d5c50a80bd9edd836b39daa1b6973359944c46d3fcc0129198dc7dc5cd0e68"),
      TestVector(language: .japanese,
                 "ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff",
                 "われる　われる　われる　われる　われる　われる　われる　われる　われる　われる　われる　われる　われる　われる　われる　われる　われる　われる　われる　われる　われる　われる　われる　らいう",
                 "a44ba7054ac2f9226929d56505a51e13acdaa8a9097923ca07ea465c4c7e294c038f3f4e7e4b373726ba0057191aced6e48ac8d183f3a11569c426f0de414623"),
      TestVector(language: .japanese,
                 "77c2b00716cec7213839159e404db50d",
                 "せまい　うちがわ　あずき　かろう　めずらしい　だんち　ますく　おさめる　ていぼう　あたる　すあな　えしゃく",
                 "344cef9efc37d0cb36d89def03d09144dd51167923487eec42c487f7428908546fa31a3c26b7391a2b3afe7db81b9f8c5007336b58e269ea0bd10749a87e0193"),
      TestVector(language: .japanese,
                 "b63a9c59a6e641f288ebc103017f1da9f8290b3da6bdef7b",
                 "ぬすむ　ふっかつ　うどん　こうりつ　しつじ　りょうり　おたがい　せもたれ　あつめる　いちりゅう　はんしゃ　ごますり　そんけい　たいちょう　らしんばん　ぶんせき　やすみ　ほいく",
                 "b14e7d35904cb8569af0d6a016cee7066335a21c1c67891b01b83033cadb3e8a034a726e3909139ecd8b2eb9e9b05245684558f329b38480e262c1d6bc20ecc4"),
      TestVector(language: .japanese,
                 "3e141609b97933b66a060dcddc71fad1d91677db872031e85f4c015c5e7e8982",
                 "くのう　てぬぐい　そんかい　すろっと　ちきゅう　ほあん　とさか　はくしゅ　ひびく　みえる　そざい　てんすう　たんぴん　くしょう　すいようび　みけん　きさらぎ　げざん　ふくざつ　あつかう　はやい　くろう　おやゆび　こすう",
                 "32e78dce2aff5db25aa7a4a32b493b5d10b4089923f3320c8b287a77e512455443298351beb3f7eb2390c4662a2e566eec5217e1a37467af43b46668d515e41b"),
      TestVector(language: .japanese,
                 "0460ef47585604c5660618db2e6a7e7f",
                 "あみもの　いきおい　ふいうち　にげる　ざんしょ　じかん　ついか　はたん　ほあん　すんぽう　てちがい　わかめ",
                 "0acf902cd391e30f3f5cb0605d72a4c849342f62bd6a360298c7013d714d7e58ddf9c7fdf141d0949f17a2c9c37ced1d8cb2edabab97c4199b142c829850154b"),
      TestVector(language: .japanese,
                 "72f60ebac5dd8add8d2a25a797102c3ce21bc029c200076f",
                 "すろっと　にくしみ　なやむ　たとえる　へいこう　すくう　きない　けってい　とくべつ　ねっしん　いたみ　せんせい　おくりがな　まかい　とくい　けあな　いきおい　そそぐ",
                 "9869e220bec09b6f0c0011f46e1f9032b269f096344028f5006a6e69ea5b0b8afabbb6944a23e11ebd021f182dd056d96e4e3657df241ca40babda532d364f73"),
      TestVector(language: .japanese,
                 "2c85efc7f24ee4573d2b81a6ec66cee209b2dcbd09d8eddc51e0215b0b68e416",
                 "かほご　きうい　ゆたか　みすえる　もらう　がっこう　よそう　ずっと　ときどき　したうけ　にんか　はっこう　つみき　すうじつ　よけい　くげん　もくてき　まわり　せめる　げざい　にげる　にんたい　たんそく　ほそく",
                 "713b7e70c9fbc18c831bfd1f03302422822c3727a93a5efb9659bec6ad8d6f2c1b5c8ed8b0b77775feaf606e9d1cc0a84ac416a85514ad59f5541ff5e0382481"),
      TestVector(language: .japanese,
                 "eaebabb2383351fd31d703840b32e9e2",
                 "めいえん　さのう　めだつ　すてる　きぬごし　ろんぱ　はんこ　まける　たいおう　さかいし　ねんいり　はぶらし",
                 "06e1d5289a97bcc95cb4a6360719131a786aba057d8efd603a547bd254261c2a97fcd3e8a4e766d5416437e956b388336d36c7ad2dba4ee6796f0249b10ee961"),
      TestVector(language: .japanese,
                 "7ac45cfe7722ee6c7ba84fbc2d5bd61b45cb2fe5eb65aa78",
                 "せんぱい　おしえる　ぐんかん　もらう　きあい　きぼう　やおや　いせえび　のいず　じゅしん　よゆう　きみつ　さといも　ちんもく　ちわわ　しんせいじ　とめる　はちみつ",
                 "1fef28785d08cbf41d7a20a3a6891043395779ed74503a5652760ee8c24dfe60972105ee71d5168071a35ab7b5bd2f8831f75488078a90f0926c8e9171b2bc4a"),
      TestVector(language: .japanese,
                 "4fa1a8bc3e6d80ee1316050e862c1812031493212b7ec3f3bb1b08f168cabeef",
                 "こころ　いどう　きあつ　そうがんきょう　へいあん　せつりつ　ごうせい　はいち　いびき　きこく　あんい　おちつく　きこえる　けんとう　たいこ　すすめる　はっけん　ていど　はんおん　いんさつ　うなぎ　しねま　れいぼう　みつかる",
                 "43de99b502e152d4c198542624511db3007c8f8f126a30818e856b2d8a20400d29e7a7e3fdd21f909e23be5e3c8d9aee3a739b0b65041ff0b8637276703f65c2"),
      TestVector(language: .japanese,
                 "18a2e1d81b8ecfb2a333adcb0c17a5b9eb76cc5d05db91a4",
                 "うりきれ　うねる　せっさたくま　きもち　めんきょ　へいたく　たまご　ぜっく　びじゅつかん　さんそ　むせる　せいじ　ねくたい　しはらい　せおう　ねんど　たんまつ　がいけん",
                 "753ec9e333e616e9471482b4b70a18d413241f1e335c65cd7996f32b66cf95546612c51dcf12ead6f805f9ee3d965846b894ae99b24204954be80810d292fcdd"),
      TestVector(language: .japanese,
                 "15da872c95a13dd738fbf50e427583ad61f18fd99f628c417a61cf8343c90419",
                 "うちゅう　ふそく　ひしょ　がちょう　うけもつ　めいそう　みかん　そざい　いばる　うけとる　さんま　さこつ　おうさま　ぱんつ　しひょう　めした　たはつ　いちぶ　つうじょう　てさぎょう　きつね　みすえる　いりぐち　かめれおん",
                 "346b7321d8c04f6f37b49fdf062a2fddc8e1bf8f1d33171b65074531ec546d1d3469974beccb1a09263440fc92e1042580a557fdce314e27ee4eabb25fa5e5fe"),
      TestVector(language: customLanguage,
                 "00000000000000000000000000000000",
                 "aband0n aband0n aband0n aband0n aband0n aband0n aband0n aband0n aband0n aband0n aband0n ab0ut",
                 "a3f1b782bc3315cea2f93e8a6db3190a18b4870afe6fb40f6e3ac2fdc2216dfe33b7ef97e31845f710231d8a7a30a49fe82df5707f4a35917a92337a4da8184d",
                 ""),
      TestVector(language: customLanguage,
                 "15da872c95a13dd738fbf50e427583ad61f18fd99f628c417a61cf8343c90419",
                 "b3y0nd 5tag3 5l33p cl1p b3cau53 tw15t t0k3n l3af at0m b3auty g3n1u5 f00d bu51n355 51d3 gr1d unabl3 m1ddl3 arm3d 0b53rv3 pa1r cr0uch t0n1ght away c0c0nut",
                 "2e9a0929ca67cd8c1a11cf71abee2c8b51c2555758f37a133ea9f491f55c352a4a831b2bf8dda61e9a4ed0ffeeae7324704f26d1304ab35ffebf8c997f73badd",
                 "")]
    return vector
  }()
  
  override func spec() {
    describe("BIP39 tests") {
      describe("Should pass all test vectors. Count: \(self.testVectors.count)") {
        for (idx, vector) in self.testVectors.enumerated() {
          it("Should pass test vector - \(idx)") {
            let entropyBIP39 = BIP39(entropy: vector.entropy, language: vector.language)
            let mnemonicBIP39 = BIP39(mnemonic: vector.mnemonic, language: vector.language)
            
            expect(entropyBIP39.mnemonic).to(equal(vector.mnemonic), description: "Mnemonic failed: \(vector.entropy.toHexString())")
            expect(mnemonicBIP39.entropy).to(equal(vector.entropy), description: "Entropy failed: \(vector.entropy.toHexString())")
            
            do {
              if case .japanese = vector.language {
                let password = "㍍ガバヴァぱばぐゞちぢ十人十色"
                let normalizedPassword = "メートルガバヴァぱばぐゞちぢ十人十色"
                
                let entropySeedPassword = try entropyBIP39.seed(password: password)
                let entropySeedNormalizedPassword = try entropyBIP39.seed(password: normalizedPassword)
                let mnemonicSeedPassword = try mnemonicBIP39.seed(password: password)
                let mnemonicSeedNormalizedPassword = try mnemonicBIP39.seed(password: normalizedPassword)
                expect(entropySeedPassword).to(equal(vector.seed), description: "Seed failed: \(vector.entropy.toHexString())")
                expect(entropySeedNormalizedPassword).to(equal(vector.seed), description: "Seed failed: \(vector.entropy.toHexString())")
                expect(mnemonicSeedPassword).to(equal(vector.seed), description: "Seed failed: \(vector.entropy.toHexString())")
                expect(mnemonicSeedNormalizedPassword).to(equal(vector.seed), description: "Seed failed: \(vector.entropy.toHexString())")
              } else {
                let entropySeed = try entropyBIP39.seed(password: vector.password ?? "")
                let mnemonicSeed = try mnemonicBIP39.seed(password: vector.password ?? "")
                expect(entropySeed).to(equal(vector.seed), description: "Seed failed: \(vector.entropy.toHexString())")
                expect(mnemonicSeed).to(equal(vector.seed), description: "Seed failed: \(vector.entropy.toHexString())")
              }
            } catch let error {
              fail("Vector failed: \(vector.entropy.toHexString()), error: \(error)")
            }
          }
        }
      }
    }
  }
}
